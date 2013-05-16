function out = TISEAN_c1(y, tau, mmm, tsep, Nref)
% Uses TISEAN routine c1 by a windows 'system' getaround
% The program computes curves for the fixed mass computation of the
% information dimension.
% Ben Fulcher 20/11/2009

N = length(y); % data length (number of samples)

% ++BF 12/5/2010 -- for some reason timeseries of length near a multiple of 512
% stalls the TISEAN routine c1... -- let's do a slight workaround by removing the
% last (few) points in this case...
freakystat = mod(N,256);
if freakystat<=6
    disp('TISEAN PROBLEM FREEZING WITH THIS LENGTH TIME SERIES!!! CRAZY, HEY?!')
    disp(['I''M IGNORING THE LAST ' num2str(freakystat+1) ' POINTS... I HOPE THIS IS OK'])
    y = y(1:end-(freakystat+1));
    N = length(y);
end


%% Check inputs
% time delay, tau
if nargin<2 || isempty(tau)
    tau = 1;
end
if strcmp(tau,'ac')
    tau = CO_fzcac(y);
elseif strcmp(tau,'mi')
    tau = CO_fmmi(y);
end

% Min/max embedding dimension, mmm
if nargin<3 || isempty(mmm)
    mmm=[2 10];
end

% Time separation, tsep
if nargin<4 || isempty(tsep)
   tsep = 0.02; % 2% of data length
end
if tsep>0 && tsep<1 % specify proportion of data length
    tsep = round(tsep*N);
end

% Number of reference points, Nref
if nargin<5 || isempty(Nref)
    Nref = 0.5; % half the total data
end
if Nref>0 && Nref<=1
    Nref = ceil(Nref*N); % specify a proportion of data length
end
if Nref > 2000, Nref = 2000; end % for time reasons.
if Nref < 100 && N > 100, Nref = 100; end % can't have less than 100 reference points

%% Write the data file

tnow = datestr(now, 'yyyymmdd_HHMMSS_FFF');
% to the millisecond (only get double-write error for same function called in same millisecond
fn = ['tisean_temp_c1_' tnow '.dat'];
dlmwrite(fn,y);
disp(['Just written temporary file ' fn ' for TISEAN'])

%% Run the TISEAN code
% run c1 code
tic
[pop res] = system(['H:\bin\c1 -d' num2str(tau) ' -m' num2str(mmm(1)) ...
                    ' -M' num2str(mmm(2)) ' -t' num2str(tsep) ' -n' ...
                    num2str(Nref) ' -o ' fn '.c1 ' fn]);
if isempty(res)
    delete(fn) % remove the temporary data file
    delete([fn '.c1']) % remove the TISEAN file write output
    disp('Call to TISEAN failed. Exiting'); return,
else
    disp(['TISEAN routine c1 took ' benrighttime(toc)])
end

% Get local slopes from c1 file output of previous call
tic
[pop res] = system(['H:\bin\c2d -a2 ' fn '.c1']);
if isempty(res)
    delete(fn) % remove the temporary data file
    delete([fn '.c1']) % remove the TISEAN file write output
    disp('Call to TISEAN failed. Exiting'); return
end

disp(['TISEAN routine c2d on c1 output took ' benrighttime(toc)])
delete(fn) % remove the temporary data file
delete([fn '.c1']) % remove the TISEAN file write output

%% Get the output
% 1) C1 (don't worry about this anymore, just the local slopes

% fid = fopen([fn '.c1']);
% s=textscan(fid,'%[^\n]');
% if isempty(s)
%     disp(['Error reading TISEAN output file ' fn '.c1'])
%     return;
% end
% s=s{1};
% c1dat = SUB_readTISEANout(s,'#m=',2);
% fclose(fid); % close the file

% keyboard

s = textscan(res,'%[^\n]');
s=s{1};
if isempty(s)
    disp(['Error reading TISEAN output file ' fn '.c1'])
    return;
end
c1dat = SUB_readTISEANout(s,'#m=',2);


% issues: x-values differ for each dimension
% spline interpolate for a consistent range
% consistent min/max range:
% 
% This works, but higher dimensions don't probe the lower length scales,
% so it's a bit tricky...
% nn = length(c1dat);
% mini=min(c1dat{1}(:,1));
% maxi=max(c1dat{1}(:,1));
% for i=2:nn
%     mini=max([mini min(c1dat{ii}(:,1))]);
%     maxi=min([maxi max(c1dat{ii}(:,1))]);
% end
% c1dat_sp = zeros(nn,50); % new splined version
% scr_sp = logspace(log10(mini),log10(maxi),50); % scale range spline
% for i=1:length(c1dat)
%     c1dat_sp(i,:) = spline(c1dat{i}(:,1),c1dat{i}(:,2),scr_sp);
% end
% % [c1dat_v c1dat_M] = SUB_celltomat(c1dat,2);
% benfindc1 = findscalingr_ind(c1dat_sp);



% Just do it for individual dimensions
c1sc = zeros(length(c1dat),6); % c1 scaling
for i=1:length(c1dat)
    try
        c1sc(i,1:5) = findscalingr_ind(c1dat{i}(:,2));
    catch
        disp('error finding scaling range')
        out = NaN;
        return
    end
end
% scaling ranges
for i = 1:length(c1dat)
   c1sc(i,1) = c1dat{i}(c1sc(i,1),1);
   c1sc(i,2) = c1dat{i}(c1sc(i,2),1);
end
c1sc(:,6) = c1sc(:,2) - c1sc(:,1);

wherebestest = find(c1sc(:,3)==min(c1sc(:,3)),1,'first');
out.bestestd = c1sc(wherebestest,4);
out.bestestdstd = c1sc(wherebestest,5);
% best fit embedding dimension

% longest scaling range estimate of embedding dimension

out.bestgoodness = min(c1sc(:,3));
out.mediand = median(c1sc(:,4));
out.mind = min(c1sc(:,4));
out.maxd = max(c1sc(:,4));
out.ranged = range(c1sc(:,4));
out.maxmd = c1sc(end,4);
out.meanstd = mean(c1sc(:,5));


wherelongestscr = find(c1sc(:,6)==max(c1sc(:,6)),1,'first');
out.bestscrd = c1sc(wherelongestscr,4);
out.longestscr = max(c1sc(:,6)); % (a log difference)


% keyboard


% s = textscan(res,'%[^\n]'); s=s{1};
% wi = strmatch('Mass',s);
% keyboard
% s = s(wi(1):end);
% me = textscan(char(s)','%s %n %[^=]%1c %n %[^=]%1c %n \n');
%  Mass   0.000114630435: k= 1, N= 4999


% c1 -d# -m# -M# -t# -n# [-## -K# -o outfile -l# -x# -c#[,#] -V# -h]  file
% 
% 
%     -d delay
%     -m minimal embedding dimension
%     -M maximal embedding dimension (at least 2)
%     -t minimal time separation
%     -n minimal number of center points
%     -# resolution, values per octave (2)
%     -K maximal number of neighbours (100)
%     -l number of values to be read (all)
%     -x number of values to be skipped (0)
%     -c column(s) to be read (1 or file,#)
%     -o output file name, just -o means file_c1
%     -V verbosity level (0 = only fatal errors)
%     -h show this message 
    

    function dimdat = SUB_readTISEANout(s,blocker,nc)
        % blocker the string distinguishing sections of output
        % nc number of columns in string
        
%         w=zeros(maxm+1,1);
%         if nargin<3 % use default blocker
%             for ii=1:maxm
%                 w(ii)=strmatch(['#dim= ' num2str(ii)],s,'exact');
%             end
%         else
%            for ii=1:maxm
%                 try
%                     w(ii) = strmatch([blocker num2str(ii)],s,'exact');
%                 catch
%                    keyboard 
%                 end
%            end
%         end
        w = strmatch(blocker,s);
%         if length(w)~=maxm
%             disp('error reading TISEAN output'); return
%         end
        maxm = length(w);
        w(end+1) = length(s)+1; % as if there were another marker at the entry after the last data row
        
        dimdat = cell(maxm,1); % stores data for each embedding dimension
        for ii=1:maxm
            ss = s(w(ii)+1:w(ii+1)-1);
            nn = zeros(length(ss),nc);
            for jj=1:length(ss)
                if nc==2
                    tmp = textscan(ss{jj},'%n%n');
                elseif nc==3
                    tmp = textscan(ss{jj},'%n%n%n');
                end
                nn(jj,:) = horzcat(tmp{:});
            end
            dimdat{ii} = nn;
        end

    end
    
    function [thevector thematrix] = SUB_celltomat(thecell,thecolumn)
        % converts cell to matrix, where each (specified) column in cell
        % becomes a column in the new matrix
        
        % But higher dimensions may not reach low enough length scales
        % rescale range to greatest common span
        nn = length(thecell);
        mini=min(thecell{1}(:,1));
        maxi=max(thecell{1}(:,1));
        for ii=2:nn
            mini=max([mini min(thecell{ii}(:,1))]);
            maxi=min([maxi max(thecell{ii}(:,1))]);
        end
        for ii=1:nn % rescales each dimension so all share common scale
            thecell{ii} = thecell{ii}(thecell{ii}(:,1)>=mini & thecell{ii}(:,1)<=maxi,:);
        end
        thevector = thecell{1}(:,1);
        ee = length(thevector);
        
        thematrix = zeros(nn,ee); % across the rows for dimensions; across columns for lengths/epsilons
        for ii=1:nn
            thematrix(ii,:) = thecell{ii}(:,thecolumn);
        end
        
    end

    function results = findscalingr_ind(x)
        % AS ABOVE EXCEPT LOOKS FOR SCALING RANGES FOR INDIVIDUAL DIMENSIONS
        % finds constant regions in VECTOR x
        % if x a matrix, finds scaling regions requiring all columns to
        % match up. (i.e., to exhibit scaling at the same time)
        % starting point must be in first half of data
        % end point must be in last half of data
        
        
        l = length(x); % number of distance/scaling points per dimension
        gamma=0.005; % regularizer: CHOSEN AD HOC!! (maybe it's nicer to say 'empirically'...)

        stptr = 1:floor(l/4)-1; % must be in the first quarter
        endptr = ceil(l/4)+1:l; % must be in second three quarters
        results = zeros(4,1); %stpt, endpt, goodness, dim
        
        mybad = zeros(length(stptr),length(endptr));
        v = x; % the vector of data for length scales
        vnorm = v; %(v-min(v))./(max(v)-min(v)); % normalize regardless of range
        for ii=1:length(stptr)
            for jj=1:length(endptr)
                mybad(ii,jj) = std(vnorm(stptr(ii):endptr(jj)))-gamma*(endptr(jj)-stptr(ii)+1);
            end
        end
        [a b] = find(mybad == min(mybad(:)),1,'first'); % this defines the 'best' scaling range
        results(1) = stptr(a);
        results(2) = endptr(b);
        results(3) = min(mybad(:));
        results(4) = mean(v(stptr(a):endptr(b)));
        results(5) = std(v(stptr(a):endptr(b)));
        
%         hold off;
%         plot(1:l,v,'o-k');
%         hold on;
%         plot(stptr(a):endptr(b),mean(v(stptr(a):endptr(b)))*ones(endptr(b)-stptr(a)+1),'--r');
%         hold off;
%         keyboard
    end


end
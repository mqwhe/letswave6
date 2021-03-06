function [out_header,out_data,message_string]=RLW_hilbert_bands(header,data,varargin);
%RLW_hilbert_bands
%
%Hilbert transform across multiple frequency bands
%
%varargin
%'freq_width'
%'freq_transition_width'
%'freq_start'
%'freq_end'
%'freq_lines'
%
% Author : 
% Andre Mouraux
% Institute of Neurosciences (IONS)
% Universite catholique de louvain (UCL)
% Belgium
% 
% Contact : andre.mouraux@uclouvain.be
% This function is part of Letswave 6
% See http://nocions.webnode.com/letswave for additional information
%

freq_width=5;
freq_transition_width=1;
freq_start=50;
freq_end=300;
freq_lines=100;

%parse varagin
if isempty(varargin);
else
    %freq_width
    a=find(strcmpi(varargin,'freq_width'));
    if isempty(a);
    else
        freq_width=varargin{a+1};
    end;
    %freq_start
    a=find(strcmpi(varargin,'freq_start'));
    if isempty(a);
    else
        freq_start=varargin{a+1};
    end;
    %freq_end
    a=find(strcmpi(varargin,'freq_end'));
    if isempty(a);
    else
        freq_end=varargin{a+1};
    end;
    %freq_lines
    a=find(strcmpi(varargin,'freq_lines'));
    if isempty(a);
    else
        freq_lines=varargin{a+1};
    end;
    %freq_transition_width
    a=find(strcmpi(varargin,'freq_transition_width'));
    if isempty(a);
    else
        freq_transition_width=varargin{a+1};
    end;
end;

%init message_string
message_string={};
message_string{1}='Hilbert transform (multiple frequency bands)';
message_string{end+1}='This can take a while!!!';

%out_header
out_header=header;

%compute forward FFT
message_string{end+1}='Computing Forward FFT';
[FFT_header,FFT_data,message_string2,time_header]=RLW_FFT(header,data,'output','complex','half_spectrum',0,'normalize',0);

%freq_vector
freq_vector=linspace(freq_start,freq_end,freq_lines);

%adjust out_header.datasize
out_header.datasize(5)=length(freq_vector);

%adjust out_header.ystart .ystep
out_header.ystart=freq_start;
out_header.ystep=freq_vector(2)-freq_vector(1);

%prepare out_data
out_data=zeros(out_header.datasize);

%loop through freq_vector
low_width=freq_transition_width;
high_width=freq_transition_width;
for freq_pos=1:length(freq_vector);
    %bandpass
    low_cutoff=freq_vector(freq_pos)-(freq_width/2);
    high_cutoff=freq_vector(freq_pos)+(freq_width/2);
    vector=ILW_buildFFTbandpass(FFT_header,low_cutoff,high_cutoff,low_width,high_width);
    for epochpos=1:size(FFT_data,1);
        for channelpos=1:size(FFT_data,2);
            for indexpos=1:size(FFT_data,3);
                for dz=1:size(FFT_data,4);
                    out_data(epochpos,channelpos,indexpos,dz,freq_pos,:)=squeeze(FFT_data(epochpos,channelpos,indexpos,dz,1,:)).*vector;
                end;
            end;
        end;
    end;
end;
    
    
%iFFT
message_string{end+1}='Computing Inverse FFT';
[out_header,out_data,message_string2]=RLW_iFFT(out_header,out_data,'time_header',time_header,'force_real',1);
message_string=[message_string message_string2];

%loop through all the data (Hilbert)
disp('Hilbert transform.');
for epochpos=1:size(out_data,1);
    disp(['E : ' num2str(epochpos)])
    for indexpos=1:size(out_data,3);
        for dz=1:size(out_data,4);
            for dy=1:size(out_data,5);
                %hilbert
                out_data(epochpos,:,indexpos,dz,dy,:)=abs(hilbert(squeeze(out_data(epochpos,:,indexpos,dz,dy,:))'))';
            end;
        end;
    end;
end

%FFT
%adjust header
%xstart
out_header.xstart=0;
%xsize=samplingrate
out_header.xstep=1/(out_header.xstep*size(out_data,6));
%filetype
out_header.filetype='time_frequency_amplitude';

%delete events
if isfield(out_header,'events');
    out_header=rmfield(out_header,'events');
end;

data=out_data;
out_data=zeros(size(data));

%loop through all the data
disp('FFT');
for epochpos=1:size(data,1);
    disp(['E : ' num2str(epochpos)])
    for channelpos=1:size(data,2);
        for indexpos=1:size(data,3);
            for dz=1:size(data,4);
                for dy=1:size(data,5);
                    out_data(epochpos,channelpos,indexpos,dz,dy,:)=abs(fft(data(epochpos,channelpos,indexpos,dz,dy,:)));
                end;
            end;
        end;
    end;
end;

out_data=out_data/size(out_data,6);

out_data=out_data(:,:,:,:,:,1:fix(size(out_data,6)/2));
out_header.datasize=size(out_data);




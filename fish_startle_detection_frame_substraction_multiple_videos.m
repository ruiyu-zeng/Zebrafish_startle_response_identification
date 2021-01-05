% This script is to identify zebrafish startle responses in videos
% We use difference in pixel number of each frame relative to the 
% first frame to quantify fish movement

% 7/20/2020: use imfindcircles() to find the arena that holds the zebrafish
% grayscale image did not work with imfindcircles, but binarizing the first
% frame made the function work

% 7/20/2020: this script is designed to analyze multiple videos at a time

% 7/23/2020: reduce error rate by thresholding and restraining the criteria
% for identifying startle responses (error rate: 0.5%)

% 8/23/2020: make some modifications to the code to improve accuracy

% detect changes in pixels in video frames
clear all; 
close all;
clc; 

directory = dir("ZIRC_AB11_startle*.avi");
%fn=uigetfile('*.txt','Select the INPUT DATA FILE(s)','MultiSelect','on');
videos = [directory.name];
names = strsplit(videos,'.avi');
names = names';
response = []';
analysis_results = struct('videoname',names,'response',response);
tic; 
for fn = 1:length(directory)
    basefilename = directory(fn).name;
    fprintf('start processing %s\n',basefilename)


    videoObject = VideoReader(basefilename); % load video file of interest

    numberOfFrames = videoObject.NumberOfFrames; % extract number of frames
    FirstFrame = read(videoObject,1); % read in the first frame of the video as the reference

    % binarize the first frame
    ff = imbinarize(FirstFrame); imshow(ff); 
    % specify properties of imfindcircles function
    [centers, radii, metric] = imfindcircles(ff, [350 450],'ObjectPolarity','bright',...
        'Sensitivity',0.99,'EdgeThreshold',0.1);

    if isempty(centers) == 1 || sum(size(centers)) >= 4
        imshow(FirstFrame); title('automatic arena selection failed; select ROI by hand');
        circle_roi = images.roi.Circle(gca,'center',[512 512],'radius',400);
        draw(circle_roi)
    else
        disp("circular arena found, proceed to ROI selection")
        circle_roi = drawcircle('Center',centers,'Radius',radii,'StripeColor','red');
    end 

    %%%%%%%%%%% CAUTION: do NOT close the image after specifying ROI%%%%%%%%%%%
    BW = createMask(circle_roi);

    % apply mask to the first frame of the video
    FirstFrame(~BW) = 0; 
    % shows the first frame and lets the user select ROI
    imshow(FirstFrame); title('ROI selected');

%     threshold = graythresh(FirstFrame); % compute the gray threshold
%     fish_thresh = threshold * max(max(FirstFrame)); % compute fish threshold
%     fish_detect = FirstFrame < fish_thresh; % isolate the fish pixels 
    
    if numberOfFrames > 500
        numberOfFrames = 500;
    end 

    for k = 1:numberOfFrames
        currentFrame = read(videoObject, k);
        currentFrame(~BW) = 0; % crop out the irrelevant regions 
        difference = FirstFrame - currentFrame; % compute difference frame
        diff_frame(:,:,:,k) = difference;
        all_frames(:,:,:,k) = currentFrame;
    end 

    for j = 1:numberOfFrames
        pixelCount(j) = sum(sum(diff_frame(:,:,j))); 
        
    end 

    x = linspace(1, numberOfFrames, numberOfFrames);

    % Apply smoothing function 
    smoothed_count = smooth(pixelCount); 

    % Design and apply butterworth notch filter
    Fs = 1000;
    d = designfilt('bandstopiir','FilterOrder',2, ...
                   'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
                   'DesignMethod','butter','SampleRate',Fs);


    smoothed_count = filtfilt(d,smoothed_count);

    % Find the gradient of pixel intensity change
    count_gradient = gradient(smoothed_count,x);
    count_gradient = count_gradient(10:end); % Eliminate the fist 10 frames 
    count_gradient = count_gradient(1:end-10); % Eliminate the last 10 frames
%     count_gradient = abs(count_gradient); % added on 8/23/2020


    %Apply thrsholding
    mean_gradient = mean(count_gradient(200:end));
    sd_gradient = std(count_gradient(200:end));
    threshold_gradient = mean_gradient + 3.5 * sd_gradient;
    key_frame = find(count_gradient > threshold_gradient);
    start_frame = find(count_gradient == max(abs(count_gradient(:))));


    %figure; 
    %plot(count_gradient,'k');
    %hold on; xline(key_frame,'g');
    %hold on; yline(threshold_gradient);
    %title('gradient of frame differences');
    
    if isempty(key_frame) == 1
      disp("no startle response detected")
      analysis_results(fn).response = 0;
    end 
    
    if min(key_frame) > 70 
      disp("no startle response detected")
      analysis_results(fn).response = 0;
    end 

    while  min(key_frame) <= 70 
        if length(key_frame) == 1 || isempty(key_frame(diff(key_frame) == 1)) ==1 
            disp("no startle response detected")
            analysis_results(fn).response = 0;
            break 
        elseif length(key_frame) > 1 && any(key_frame(:) == start_frame) && length(key_frame(diff(key_frame) == 1)) >= 1
            disp("the fish displayed startle response")
            analysis_results(fn).response = 1;
            break
        end 
    end 
    
    if isempty(analysis_results(fn).response) ==1
        analysis_results(fn).response = "NA";
    end 
    
    fprintf('finished processing %s\n\n',basefilename);
    
    close all;
    clearvars -except directory analysis_results response names
  
end


names(end) = [];
startle = [analysis_results.response]'; 
video_coding = table(names, startle);
toc; 
save("AB11_habituation_analysis_count_gradient", "video_coding");

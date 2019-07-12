% NuRF
% Jeffrey Tang
% 1/15/13

% NuRF (Nuclear Rim Fluorescence Analyzer)
%
% This script segments the nuclear rim of HeLa cell nuclei using binary
% thresholding of the nuclei and morphology operations to isolate the
% nuclear rim. Poorly segmented regions can be corrected by the user
% through manual removal and addition of segments.

close all;
clear all;

%clear all

% USER INPUTS
filename = 'C:\Documents and Settings\Jeff\My Documents\Jeff\Data\130725_misc_expts\M1_fov1_lsm.tif';
thresh_param = 1.4; % Thresholding parameter
erosion_param = 3; % Parameter for erosion operation
dilation_param = 2; % Parameter for dilation operation
green_brightness = 1; % To adjust relative brightness of green channel
red_brightness = 200; % To adjust relative brightness of red channel

% Read image files
im = imread(filename,3); % Green channel
im2 = imread(filename,1); % Red channel

% Determine threshold parameter
vec = reshape(im,1,size(im,1)*size(im,2));
thresh = (mean(single(vec))*thresh_param)/255.0;

% Filter image (2D median filter)
im_filt = medfilt2(im,[3 3]);

% Segment image
im_seg = im2bw(im_filt,thresh); % Binary thresholding
im_seg = bwareaopen(im_seg,200,8); % Remove small objects
im_seg = imfill(im_seg,'holes'); % Fill in objects

% Remove border pixels from segmented image
im_seg(1:512,1) = 0; % Left border
im_seg(1,1:512) = 0; % Top border
im_seg(1:512,512) = 0; % Right border
im_seg(512,1:512) = 0; % Bottom border

% Remove nuclear rim from nucleus
im_seg = imerode(im_seg,strel('disk',erosion_param));

% Display image
figure;
set(gcf,'OuterPosition',[450 25 1200 1200]);
IM = uint8(zeros(512,512,3));
IM(:,:,2) = im*green_brightness; % Green channel
IM(:,:,1) = uint8(im_seg*red_brightness); % Red channel
image(IM);

% Manual removal of poorly segmented regions
stop = 0;
while stop==0
    foo = waitforbuttonpress;
    point1 = get(gca,'CurrentPoint');
    rect = rbbox;
    point2 = get(gca,'CurrentPoint');
    for i=round(point1(1,1)):round(point2(1,1))
        for j=round(point1(1,2)):round(point2(1,2))
            im_seg(j,i) = 0;
        end
    end
    IM(:,:,1) = uint8(im_seg*red_brightness);
    image(IM);
    reply = input('Complete?','s');
    if ~isempty(reply)
        stop = 1;
    end
end

% Isolate nuclear rim
im_seg_dil = imdilate(im_seg,strel('disk',dilation_param)); % Add nuclear rim
im_seg_nucrim = im_seg_dil & ~im_seg;

% Display image
IM = uint8(zeros(512,512,3));
IM(:,:,2) = im*green_brightness; %green
IM(:,:,1) = uint8(im_seg_nucrim*red_brightness); %red
image(IM);

% Manual removal of poorly segmented nuclear rim regions
stop = 0;
while stop==0
    foo = waitforbuttonpress;
    point1 = get(gca,'CurrentPoint');
    rect = rbbox;
    point2 = get(gca,'CurrentPoint');
    for i=round(point1(1,1)):round(point2(1,1))
        for j=round(point1(1,2)):round(point2(1,2))
            im_seg_nucrim(j,i) = 0;
        end
    end
    IM(:,:,1) = uint8(im_seg_nucrim*red_brightness);
    image(IM);
    reply = input('Complete?','s');
    if ~isempty(reply)
        stop = 1;
    end
end

% Manual addition of poorly segmented nuclear rim regions
stop = 0;
while stop==0
    foo = waitforbuttonpress;
    point1 = get(gca,'CurrentPoint');
    rect = rbbox;
    point2 = get(gca,'CurrentPoint');
    for i=round(point1(1,1)):round(point2(1,1))
        for j=round(point1(1,2)):round(point2(1,2))
            im_seg_nucrim(j,i) = 1;
        end
    end
    IM(:,:,1) = uint8(im_seg_nucrim*red_brightness);
    image(IM);
    reply = input('Complete?','s');
    if ~isempty(reply)
        stop = 1;
    end
end

% Compute nuclear rim region properties
nucrim_prop = regionprops(im_seg_nucrim,im,'Centroid','MeanIntensity');
nucrim_prop2 = regionprops(im_seg_nucrim,im2,'Centroid','MeanIntensity');
num = size(nucrim_prop);

hold on;
for i=1:num(1)
    text(nucrim_prop(i).Centroid(1),nucrim_prop(i).Centroid(2),num2str(i),'Color','c');
end
mean_intensities = cat(1,nucrim_prop.MeanIntensity);
mean_intensities2 = cat(1,nucrim_prop2.MeanIntensity);
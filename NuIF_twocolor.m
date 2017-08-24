% NuIF_twocolor
% Jeffrey Tang
% 6/1/11

% NuIF (Nuclear Interior Fluorescence Analyzer) for two-color images
%
% This script segments two-channel fluorescence images of HeLa cell nuclei 
% using global thresholding (against the user-selected background
% fluorescence). Poorly segmented regions can be corrected by the user 
% through manual removal and addition of segments.

close all;
clear all;

% USER INPUTS
filename = 'C:\Documents and Settings\Jeff\My Documents\Jeff\Data\130725_misc_expts\M3_fov3_lsm.tif';
bgd_thresh_parameter = 1.5; % To adjust background fluorescence thresholding
erosion_parameter = 7; % To adjust degree of nuclear rim 'erosion'
raw_image_scale = 2; % To adjust 'brightness' of raw image overlay
bf_image_scale = 0; % To adust 'brightness' of brightfield image
color_balance = 150; % To adjust color balance between overlay of raw and segmented images
invert = 0; % 0 = Don't invert, 1 = invert

% Read in image files
imA = imread(filename,1); % Fluorescent protein image
imB = imread(filename,2); % Dextran image
imC = imread(filename,2); % Brightfield image

% Invert the dextran image
if invert==1
    meanimB = mean(mean(imB));
    im = 2.*meanimB - imB;
else
    im = imA;
end

figure;
set(gcf,'OuterPosition',[450 50 900 900]);

% Determine background fluorescence threshold value (user-selected area)
imagesc(im);
foo = waitforbuttonpress;
point1 = get(gca,'CurrentPoint');
rect = rbbox;
point2 = get(gca,'CurrentPoint');
max_bgd = 0;
for i=round(point1(1,1)):round(point2(1,1))
    for j=round(point1(1,2)):round(point2(1,2))
        if max_bgd<im(j,i)
            max_bgd=im(j,i);
        end
    end
end
bgd_thresh = double(max_bgd)*bgd_thresh_parameter/255;

% Segmenting nuclei
im1 = im2bw(im,bgd_thresh); % Intensity thresholding
im2 = bwareaopen(im1,5,8); % Remove very small, isolated objects
im3 = imdilate(im2,strel('disk',1)); % Image dilation to retain 'incomplete nuclei'
im4 = bwareaopen(im3,10,8); % Remove small, isolated objects
im5 = imfill(im4,'holes'); % Fill in large objects
im6 = imclearborder(im5); % Remove objects on the image border
im7 = imerode(im6,strel('disk',erosion_parameter')); % Image erosion to remove nuclear rims
im8 = bwareaopen(im7,10,8); % Remove small, isolated objects

% Display overlay of raw image and segmented images
IM = uint8(zeros(512,512,3));
IM(:,:,1) = uint8(im8.*color_balance) + imC*bf_image_scale;
IM(:,:,2) = im.*raw_image_scale + imC*bf_image_scale;
IM(:,:,3) = imC*bf_image_scale;
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
            im8(j,i) = 0;
        end
    end
    IM(:,:,1) = uint8(im8.*color_balance) + imC*bf_image_scale;
    image(IM);
    reply = input('Complete?','s');
    if ~isempty(reply)
        stop = 1;
    end
end

% Manual addition of poorly segmented regions
stop = 0;
while stop==0
    foo = waitforbuttonpress;
    point1 = get(gca,'CurrentPoint');
    rect = rbbox;
    point2 = get(gca,'CurrentPoint');
    for i=round(point1(1,1)):round(point2(1,1))
        for j=round(point1(1,2)):round(point2(1,2))
            im8(j,i) = 1;
        end
    end
    IM(:,:,1) = uint8(im8.*color_balance) + imC*bf_image_scale;
    image(IM);
    reply = input('Complete?','s');
    if ~isempty(reply)
        stop = 1;
    end
end

IM(:,:,2) = uint8(imA.*raw_image_scale) + imC*bf_image_scale;
image(IM);

% Compute segmented region properties
pA = regionprops(im8,imA,'Centroid','MeanIntensity','Area');
pB = regionprops(im8,imB,'Centroid','MeanIntensity','Area');
num = size(pA);
hold on;
for i=1:num(1);
    text(pA(i).Centroid(1),pA(i).Centroid(2),num2str(i),'Color','c');
end
mean_intensities = double(zeros(num(1),2));
mean_intensities(:,1) = cat(1,pA.MeanIntensity);
mean_intensities(:,2) = cat(1,pB.MeanIntensity);
areas = cat(1,pA.Area);

disp('Completed without errors.');
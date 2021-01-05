# Zebrafish_startle_response_identification

### This project relates to my dissertation project. 

### Goal of this code (written in Matlab R2020a) is to identify fast startle response from individual adult zebrafish behavior videos. 

#### The basic principle of the code is to import a series of zebrafish behavior videos, then the code would identify the region of interest in the videos. Based on my experimental set up, the region of interest is a circular disk, therefore the imfindcircles() function in Matlab can easily detect the region of interest for the fish. 

#### The first frame of the video is then going to be substracted from each subsequent frame of the video. The summation of all pixels in each difference frame is then calculated. 

#### Because the fast startle response in zebrafish is very stereotypical and occurs in a short amount of time (< 50ms), the code then compute the gradient values for all difference frames. Thresholding is then applied to identify when startle response occurs in a single video. 

#### Below is the screenshot of what a startle response looks like in my setup 



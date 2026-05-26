% Script to calculate the instantaneous velocities and directions of motion
% along all of the trajectories in the file 'Trajectories'. The velocities
% are calculated in two ways: 1) as forward finite difference; 2) using a
% smoothing spline. The directions are calculated as the angle of the speed
% with respect to the positive x-axis. Therefore there are two angles for
% each trajectory point, one calculated with the velocity from point 1)
% above, and one corresponding to the velocity in point 2) above.
%
%The script loads the 'Trajectories' file from the input folder (see below)
%and saves in the output folder the file "Trajectories_and_Velocities.mat"
%containing the array "TrajVel". This array is a copy of "Trajectories",
%but with the following columns:
%(x,y,vx1,vy1,theta1,vx2,vy2,theta2,frame,particle_id)
%Here columns 1,2,9,10 corresponds to the 4 columns of "Trajectories".
%(vx1,vy1,theta1) are the velocity and angle estimated with method 1)
%(vx2,vy2,theta2) are the velocity and angle estimated with method 2)
%
%Output data are saved in the output folder provided.
%Some extra info is provided as estimates of average speed, average angular
%direction, histograms of speed distributions and of angular direction
%distribution.
%
%HISTORY
%   29 Nov. 2024. SKC & MP: Created
%

%% Clear all variables and close all figures; declaration of auxiliary variables
close all;
clear;

basepath='E:/data_analysis_kubra/'; %path to the parent directory of the movie dir
imgsdir = 'control2/'; %name of the directory with the images to analyse
resultsdir = 'tracking/';
SmoothingParam = 0.07;

InputFolder = [basepath,resultsdir,imgsdir];
OutputFolder = [basepath,resultsdir,imgsdir];

%% Load the trajectories and prepare output array
load([InputFolder,'Trajectories.mat']);
trajlbl =  unique(Trajectories(:,4)); %particle labels for the particles in the trajectories
Ntraj = length(unique(Trajectories(:,4)));
TrajVel = [Trajectories(:,1:2),0*Trajectories(:,1:3),0*Trajectories(:,1:3),Trajectories(:,3:4)]; %this matrix will contain the trajectories and the estimates for the instantaneous velocities in the x-a dn y- directions

%% Estimate velocities and directions
for tt = 1:Ntraj
    %extract the trajectory
    ww = Trajectories(:,4)== trajlbl(tt);
    mytraj = Trajectories(ww,1:3); %current trajectory

    %Estimate the instantaneous velocity from the frame-to-frame displacements
    %(this could be changed to a centred difference to get a better estimate)
    mydelta = (mytraj(2:end,:)-mytraj(1:end-1,:));
    myvel = mydelta(:,1:2)./mydelta(:,3);
    myvel = [myvel;myvel(end,:)]; %assign to the last frame the same velocity of the previous one.
    TrajVel(ww,3:4) = myvel;
    TrajVel(ww,5) = angle(myvel(:,1)+i*myvel(:,2));

    %Estimate the instantaneous velocity with smoothing splines
    [fitted_curve_x,gofx] = fit(mytraj(:,3),mytraj(:,1),'smoothingspline','SmoothingParam',SmoothingParam);
    [fitted_curve_y,gofy] = fit(mytraj(:,3),mytraj(:,2),'smoothingspline','SmoothingParam',SmoothingParam);
    TrajVel(ww,6) = differentiate(fitted_curve_x,mytraj(:,3));
    TrajVel(ww,7) = differentiate(fitted_curve_y,mytraj(:,3));
    TrajVel(ww,8) = angle(TrajVel(ww,6)+i*TrajVel(ww,7));

end

%% Save result and write averages on prompt
save([OutputFolder,'Trajectories_and_Velocities.mat'],"TrajVel");

disp('The average speed is')
disp(['Forward difference: ',num2str(mean(sqrt(TrajVel(:,3).^2+TrajVel(:,4).^2))),' \pm ',num2str(std(sqrt(TrajVel(:,3).^2+TrajVel(:,4).^2)))])
disp(['Smoothing spline: ',num2str(mean(sqrt(TrajVel(:,6).^2+TrajVel(:,7).^2))),' \pm ',num2str(std(sqrt(TrajVel(:,6).^2+TrajVel(:,7).^2)))])

disp('The average orientation angle is')
disp(['Forward difference: ',num2str(mean(TrajVel(:,5))),' \pm ',num2str(std(TrajVel(:,5)))])
disp(['Smoothing spline: ',num2str(mean(TrajVel(:,8))),' \pm ',num2str(std(TrajVel(:,8)))])

%% Miscellaneous plots
figure(1)
histogram(sqrt(TrajVel(:,3).^2+TrajVel(:,4).^2));
hold on
histogram(sqrt(TrajVel(:,6).^2+TrajVel(:,7).^2));
legend('Forward finite difference','Smoothing spline');
title('Histogram of instantaneous feature speeds');
xlabel('Feature speed (pxl/frame)');

figure(2)
histogram(TrajVel(:,5),50);
hold on
histogram(TrajVel(:,8),50);
legend('Forward finite difference','Smoothing spline');
title('Histogram of instantaneous orientation');
xlabel('Feature orientation (rad)');






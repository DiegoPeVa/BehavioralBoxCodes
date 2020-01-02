clear all
close all 

  
Screen('Preference', 'SkipSyncTests', 1);

% Go-NoGo discrimination task, first code 
 
     
  
mfilename('fullpath') 
%data recording Directory 
baseDirectory = 'Y:\recordedData\Behavioral\Ehsan';
%  
% try winopen(baseDirectory)  
% end  
   
  
if ~exist(baseDirectory, 'dir')
      baseDirectory = 'C:\recordedData\Behavioral\Ehsan'; 
end  
    
% entering the mouse Numbers, session duration and the session number of 
% the day  
prompt = {'Enter the mouse number:','Enter the box number:','Enter the mouse session number:','Enter the reward vol:','Enter the trial numbers:','Enter reinforcement trial numbers:'}; 
titleBox = 'Input';
dims = [1 35]; 
dialogBoxInputs = inputdlg(prompt,titleBox,dims);

mouseNumber = dialogBoxInputs{1};
boxNumber = dialogBoxInputs{2};
sessionNumber = dialogBoxInputs{3};
earnedRewardVol = str2num(dialogBoxInputs{4});
totalTrialNo = str2num(dialogBoxInputs{5});
freeRewardTrials = str2num(dialogBoxInputs{6});
 


 
% data folder name
dataFolderName = 'Mouse' + string(mouseNumber) + '_' + datestr(date,'mm-dd-yyyy') + '_Session' + sessionNumber + '_' + mfilename;
 
%making the folder for saving the data
mkdir(baseDirectory,dataFolderName);
dataFolderAdd = string(baseDirectory) + '\' + dataFolderName;

niDevName = 'Dev1';
%Initialization of the required daq card sessions

%Analog input session for recording the following signals:
signalsRecordingSession = daq.createSession('ni');  
%1- output of the right lick sensor AI1
%2- copy of the step motor command AI2
%3- output to the speaker AI3
%4- trial tags (sent through the daq card) AI5
%5- photodiode signal (sensed on the screens) AI0
%6- copy of the sound sent to the speaker AI4

addAnalogInputChannel(signalsRecordingSession,niDevName,0,'Voltage');
addAnalogInputChannel(signalsRecordingSession,niDevName,1,'Voltage');
addAnalogInputChannel(signalsRecordingSession,niDevName,2,'Voltage');
addAnalogInputChannel(signalsRecordingSession,niDevName,3,'Voltage');
addAnalogInputChannel(signalsRecordingSession,niDevName,4,'Voltage');
addAnalogInputChannel(signalsRecordingSession,niDevName,5,'Voltage');
% addAnalogInputChannel(signalsRecordingSession,niDevName,6,'Voltage');
% addAnalogInputChannel(signalsRecordingSession,niDevName,7,'Voltage');
% addAnalogInputChannel(signalsRecordingSession,niDevName,15,'Voltage');

%Digital output session for tagging the trials
trialDigitalTagSession = daq.createSession('ni');
%1 - digital tag sent before the stim onset
stimTagPortLine = 'port0/line2';
addDigitalChannel(trialDigitalTagSession,niDevName,stimTagPortLine,'OutputOnly');

trialDigitalTagSession.outputSingleScan(0);

% Digital input session for monitoring the spout
spoutSession = daq.createSession('ni');

%right spout sensor
sensorCopyPortLine1 = 'port0/line1';
addDigitalChannel(spoutSession,niDevName,sensorCopyPortLine1,'InputOnly');


%Digital Output session for right reward control
rewardStepMotorCtl1 = daq.createSession('ni');
rewardPortLine1 = 'port0/line0';
%1 - output to step motor to control the reward
rewardStepMotorCtl1.addDigitalChannel(niDevName,rewardPortLine1,'OutputOnly');

% %Digital Output session for left reward control
% rewardStepMotorCtl1 = daq.createSession('ni');
% rewardPortLine2 = 'port0/line4';
% %1 - output to step motor to control the reward
% rewardStepMotorCtl1.addDigitalChannel(niDevName,rewardPortLine2,'OutputOnly');
    
% Reward Volume:
% earnedRewardVol = 6; %in microL
freeRewardVol = 4;
syringeVol = 5;

% enable recording the camera for the correct synchronization 
% cameraRecordingEnable = 1;

% %Stoping the code until the camera recording started
% if cameraRecordingEnable
%     cameraRecordingStartDialogMirrorScreens;
% end


%Configuring the session for recording analog inputs
signalsRecordingSession.Rate = 3e3;
for chNo=1:size(signalsRecordingSession.Channels,2)
    signalsRecordingSession.Channels(1,chNo).TerminalConfig = 'SingleEnded';
end
signalsRecordingSession.IsNotifyWhenDataAvailableExceedsAuto = 0;
signalsRecordingSession.IsContinuous = true;
inputSavingDur = 1; %based on the warning, 0.05 seconds is the minimum saving time that is possible, (higher interval to less affect the timings in the code!)
signalsRecordingSession.NotifyWhenDataAvailableExceeds = floor(signalsRecordingSession.Rate * inputSavingDur);

%recording data through the listener, we will also analyze the input data
%for detecting the licks by sending a copy of the lick sensor to a digital
%input
binFile = dataFolderAdd + '\' + 'synchedNI-CardInputs.bin';
fid1 = fopen(binFile,'w');
lh = signalsRecordingSession.addlistener('DataAvailable',@(src, event)logData(src, event, fid1));





%----------------------------Configuration of PTB--------------------------

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

%Screen('Preference', 'SkipSyncTests', 1);
% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer.
screens = Screen('Screens');


% selecting the screen for the stimulus presentation: mirroring two
% identical screens show them with one number here.
screenNumber = 2;%max(screens);%

window = Screen('OpenWindow', screenNumber);

% load C:\Users\Stimulation\Documents\MatlabScripts\AsusGammaTable23April2019SophiePhotometer
% Screen('LoadNormalizedGammaTable', window, gammaTable*[1 1 1]);


% Define black and white (white will be 1 and black 0). This is because
% in general luminace values are defined between 0 and 1 with 255 steps in
% between. All values in Psychtoolbox are defined between 0 and 1
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Do a simply calculation to calculate the luminance value for grey. This
% will be half the luminace values for white
gray=(white+black)/2;
photoDiodeGray1 = gray/5;  %during gray screen
photoDiodeGray2 = gray/2;  %during stimulus
% if round(gray)==white
%     gray=black;
% end

% Taking the absolute value of the difference between white and gray will
% help keep the grating consistent regardless of whether the CLUT color
% code for white is less or greater than the CLUT color code for black.
absoluteDifferenceBetweenWhiteAndGray = abs(white - gray);

% Open an on screen window using PsychImaging and color it white. (or the
% default stimulus with white under the photo-diode area)

[scrWidthPix, scrHeightPix]=Screen('WindowSize',screenNumber);
% Measure the vertical refresh rate of the monitor
ifi = Screen('GetFlipInterval', window);

% set the priority level of this thread as the highest
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);


%Defines the patch of screen sitting in front of the photodiaode in order
%ot send the change stim signal before downsampling anything
% patchRect = [(scrWidthPix - (scrWidthPix/25)) 0 scrWidthPix (scrHeightPix/15)];
% patchRect = [(scrWidthPix*2/3 - (scrWidthPix/3/25)) 0 scrWidthPix*2/3 (scrHeightPix/15)];
patchRect = [scrWidthPix-(scrWidthPix/10) 0 (scrWidthPix) (scrHeightPix/6)];


%--------------------
% Gabor information
%--------------------

%Asus Screen Size: width (20.9235 inches, 53.1456 cm) height (11.7694
%inches, 29.8944 cm), pixel density: 91.76 pixels/inch
pixelDensityCM = (1280+720)/(15.41+9.05); %pixels/cm, this is approximate because the pixel density don't match for width and height

% Dimension of the region where will draw the Gabor in pixels
% Dimension of the region where will draw the Gabor in pixels
gaborDimCM_Height = 9.5; 
gaborDimPixHeight = floor(gaborDimCM_Height*pixelDensityCM); %windowRect(4) / 2;

gaborDimCM_Width = 14; 
gaborDimPixWidth = floor(gaborDimCM_Width*pixelDensityCM); %windowRect(4) / 2;

% Sigma of Gaussian
gaussianSigma = 0; %5
sigma = gaborDimCM_Height / gaussianSigma;

% Obvious Parameters
orientationPreferred = 0;
orientationNonPreferred = 90;
contrast = 100; %100
aspectRatio = 2.0;
phase = 0;

temporalFreq = 2;
degPerSec = 360 * temporalFreq;
degPerFrame =  degPerSec * ifi;
phaseLine = 0;

% Numer of frames to wait before re-drawing
waitframes = 1;

% Spatial Frequency (Cycles Per Pixel)
% One Cycle = Grey-Black-Grey-White-Grey i.e. One Black and One White Lobe
spatialFrequency = 0.3; %cycles/cm

%freq = numCycles / gaborDimPix;
freq = spatialFrequency / pixelDensityCM; %cycles/pixel



% Build a procedural gabor texture (Note: to get a "standard" Gabor patch
% we set a grey background offset, disable normalisation, and set a
% pre-contrast multiplier of 0.5.
% For full details see:
% https://groups.yahoo.com/neo/groups/psychtoolbox/conversations/topics/9174
backgroundOffset = [0.5 0.5 0.5 0.0];
disableNorm = 1;
preContrastMultiplier = 0.5;
gabortex = CreateProceduralGabor(window, gaborDimPixWidth, gaborDimPixHeight, [],...
    backgroundOffset, disableNorm, preContrastMultiplier);

% gabortexMirror = CreateProceduralGabor(window, gaborDimPix, gaborDimPix, [],...
%     backgroundOffset, disableNorm, preContrastMultiplier);

% Randomise the phase of the Gabors and make a properties matrix.
propertiesMat = [phase, freq, sigma, contrast, aspectRatio, 0, 0, 0];


%---------------------Camera and NI-Card Recording 

% Black is the default value under the photodiode and on the screen, Flip the default screen
% with White under the photo-diode
Screen('FillRect', window, gray);
Screen('FillRect',window, black, patchRect);
Screen('Flip', window);



% %Stoping the code until the camera recording started
% if cameraRecordingEnable
%     cameraRecordingStartDialogMirrorScreens;
% end
% 
% 
% Screen('FillRect', window, gray);
% Screen('FillRect',window, black, patchRect);
% Screen('Flip', window);
% 
%start the recording of signals
signalsRecordingSession.startBackground();
disp('Start recording...')

%Stoping the code until the camera trigger is disabled manually
% if cameraRecordingEnable
%     cameraTriggerDisableDialogMirrorScreens;
% end

Screen('FillRect', window, gray);
Screen('FillRect',window, black, patchRect);
Screen('Flip', window);

% making the punishment sound and the NI-card config for the sound output
% punishmentSoundDur = 0.3;
% samplingFreq = 100e3;
% punishmentSoundFreq = 3000;
punishmentSoundAmp = 1;
% 
% t = 0:1/samplingFreq:punishmentSoundDur;
% punishmentSoundToNICard = punishmentSoundAmp*sin(2*pi*punishmentSoundFreq*t);

punishmentSoundDur = 0.2;
freqChangeDur = 0.01;
numberOfIndividualDurs = floor(punishmentSoundDur/freqChangeDur);



samplingFreq = 5e3;

tPunishment = 0:1/samplingFreq:punishmentSoundDur;



% making the cue sound and the NI-card config for the sound output
cueSoundDur = 0.2;
cueSoundDurFrames = round(cueSoundDur/ifi);
% samplingFreq = 100e3;
cueSoundFreq = 2400;
cueSoundAmp = 0.2;
      
tCue = 0:1/samplingFreq:cueSoundDur;
cueSoundToNICard = cueSoundAmp*sin(2*pi*cueSoundFreq*tCue);

% niDevName = 'Dev2';
soundOutputSession = daq.createSession('ni');  

addAnalogOutputChannel(soundOutputSession,niDevName,0,'Voltage');
soundOutputSession.Rate = samplingFreq;
%--------------------------------------------------------------------------

deliverReward(earnedRewardVol,syringeVol,rewardStepMotorCtl1);
% deliverReward(earnedRewardVol,syringeVol,rewardStepMotorCtl1);

% Stimulus Parameters
heightOffsetInCM = 0;
heightOffset = floor(heightOffsetInCM*pixelDensityCM);
widthOffset = 0;

stimHeightOffset = [0,heightOffset,0,gaborDimPixHeight+heightOffset];
righImageHorzPos = [0,0,gaborDimPixWidth,0];
% righMirrorImageHorzPos = [0,0,2*gaborDimPix,0];



    

% durationToCheckLeverPress = 3; %stop duration for checking lick sensor in sec 
% minimumPressDuration = 1; % start at 1 in sec

% noLickDuration = 0.5; % start at 0.5


  
preferredStimDuration = 2; %in sec
preferredStimFrames = round(preferredStimDuration/ifi);

nonPreferredStimDuration = 2;
nonPreferredStimFrames = round(nonPreferredStimDuration/ifi);

afterStimGrayTime = 4;
afterStimGrayFrames = round(afterStimGrayTime/ifi);

afterStimExtendedGrayTime = 8;
afterStimExtendedGrayFrames = round(afterStimExtendedGrayTime/ifi);

% afterRewardStimTime = 6;
% afterRewardStimFrames = round(afterRewardStimTime/ifi);
% 
% afterWrongLickWhiteScreenTime = 6;
% afterWrongLickStimFrames = round(afterWrongLickWhiteScreenTime/ifi); 
 
stimRewardDelay = 0; %delay between the stim presentation and sensor monitoring start time

cueStimFixedDelayTime = 0;
cueStimFixedDelayFrames = round(cueStimFixedDelayTime/ifi);

cueStimJitterDelayTime = 0;
cueStimJitterDelayFrames = round(cueStimJitterDelayTime/ifi);

% durationToCheckLeverRelease = 2;
% minimumReleaseDur = 0.2;
    

% estimatedTrialDur = cueSoundDur + cueStimFixedDelayTime + cueStimJitterDelayTime/2 + preferredStimDuration + afterStimGrayTime;
% totalTrialNo = floor(sessionDurInMin*60/estimatedTrialDur);

% totalTrialNo = 200;

preferredStimCounter = 0;
hitCounter = 0;
missedCounter = 0;
NonPreferredStimCounter = 0;
earnedRewardCounterL = 0;
correctRejectionCounter = 0;
pressFlag = 0;
right = 0;
stimVector = [];
stimPresTime = [];
manualFinish = 0;
manualReward = 0;
oneSideStuck = 0;
earnedRewardVolTotal = 0;
allPhases = [];

rewardedTrial = 0;
previousSide = 0; %

rewardCounter = 1;
falseAlarmCounter = 0;
rewardCompRate = 1.5;

sameOrientation = 1;
maxSameOrientationNo = 2;

firstLicksSide = [];

consecutiveNoRewardCounter = 0;
consecNoRewardMax = 10;
afterfreeRewardWaitTime = 2;

freeRewardTrial = [];

KbWait;
startRecTime = GetSecs();

currentTrialOrientation = randi(2) - 1; % 1 is the preferred/rewarded Stim and 0 is non-rewarded
previousTrialOrientation = ~currentTrialOrientation;

goProb = 0.5; 
noLickDurBeforeStim = 2; % in sec




for trialNo=1:totalTrialNo
    
    if ~rewardedTrial
        consecutiveNoRewardCounter = consecutiveNoRewardCounter + 1;
    else
        consecutiveNoRewardCounter = 0;
    end
%     previousTrialReward = rewardedTrial;
    rewardedTrial = 0;
    punishedTrial = 0;
    
    if consecutiveNoRewardCounter == consecNoRewardMax
        
            if mod(rewardCounter,10) == 0
                   earnedRewardVol = earnedRewardVol*rewardCompRate;
            end
            deliverReward(earnedRewardVol,syringeVol,rewardStepMotorCtl1);
            earnedRewardVolTotal = earnedRewardVolTotal + earnedRewardVol;
            if mod(rewardCounter,10) == 0
                earnedRewardVol = earnedRewardVol/rewardCompRate;
            end
            freeRewardTime = GetSecs;
            rewardCounter = rewardCounter + 1;
            
             disp(['free reward ']);
             disp([' ']);
            
            consecutiveNoRewardCounter = 0;
            
            while((GetSecs - freeRewardTime) < afterfreeRewardWaitTime)
                ;
            end 
            
            freeRewardTrial = [freeRewardTrial trialNo];
    end
    
    phase = 360*rand;
    allPhases = [allPhases phase];
    propertiesMat = [phase, freq, sigma, contrast, aspectRatio, 0, 0, 0];
    
%     randomFreqVec = (randi(4,1,numberOfIndividualDurs)+3)*1e3;
%     punishmentSound = zeros(size(tPunishment));
% 
%     for freqNo=1:numberOfIndividualDurs
% 
%         tIndividualDur = tPunishment(floor(1+(freqNo-1)*samplingFreq*freqChangeDur):floor(freqNo*freqChangeDur*samplingFreq));
% 
%         punishmentSound(floor(1+(freqNo-1)*samplingFreq*freqChangeDur):floor(freqNo*freqChangeDur*samplingFreq)) = (square(2*pi*randomFreqVec(freqNo)*tIndividualDur)+1)/2;
%     end
%     
%     punishmentSoundToNICard = punishmentSoundAmp*2*(punishmentSound - 0.5);
    
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
    if (find(keyCode) == 27)  %Press escape to manually finish the loop
        break;
    end
    
    
%     Screen('FillRect', window, gray);
%     Screen('FillRect',window, black, patchRect);
%     Screen('Flip', window);
    
    % trial orientation
    if sameOrientation >= maxSameOrientationNo
        currentTrialOrientation = ~currentTrialOrientation;
    else
%         currentTrialOrientation = randi(2) - 1;
        if rand < goProb
            currentTrialOrientation = 1;
        else
            currentTrialOrientation = 0;
        end
    end
    
    while (find(keyCode) == 82)  %Press r to manually give a reward and force a go trial
        
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
            
            if mod(rewardCounter,10) == 0
                   earnedRewardVol = earnedRewardVol*rewardCompRate;
            end
            deliverReward(earnedRewardVol,syringeVol,rewardStepMotorCtl1);
            earnedRewardVolTotal = earnedRewardVolTotal + earnedRewardVol;
            if mod(rewardCounter,10) == 0
                earnedRewardVol = earnedRewardVol/rewardCompRate;
            end
            
            rewardCounter = rewardCounter + 1;    
            
            currentTrialOrientation = 1;
    end

    if currentTrialOrientation == previousTrialOrientation
        sameOrientation = sameOrientation + 1;
    else
        sameOrientation = 1;
    end
    
    previousTrialOrientation = currentTrialOrientation;
    stimVector = [stimVector currentTrialOrientation];
                
%     sound cue presentation
%     queueOutputData(soundOutputSession,cueSoundToNICard');

    Screen('FillRect', window, gray);
    Screen('FillRect',window, white, patchRect);
    
    while (1)
        scanStartTime = GetSecs;
        [lickFlag, relDetectionTime] = detectLickOnRight(noLickDurBeforeStim, spoutSession);
        if ~lickFlag
            cuePresTime = scanStartTime + relDetectionTime;
            break;
        end
    end
        
%     cuePresTime = GetSecs;
%     soundOutputSession.startBackground;
%     wait(soundOutputSession);
%     
    
    if cueStimJitterDelayTime
        totalCueStimDelayFrames = cueStimFixedDelayFrames + randi(cueStimJitterDelayFrames);
    else
        totalCueStimDelayFrames = cueStimFixedDelayFrames;
    end
    
    


    if currentTrialOrientation
        
        preferredStimCounter = preferredStimCounter + 1;
% this is the preferred stimulus
        Screen('DrawTextures', window, gabortex, [], righImageHorzPos+stimHeightOffset, orientationPreferred, [], [], [], [],...
            kPsychDontDoRotation, propertiesMat');
% 
%         Screen('DrawTextures', window, gabortex, [], righMirrorImageHorzPos+stimHeightOffset, orientationPreferred, [], [], [], [],...
%             kPsychDontDoRotation, propertiesMat');
        trialDigitalTagSession.outputSingleScan(1);
        [vblStim StimulusOnsetTime FlipTimestampStim MissedStim BeamposStim] = Screen('Flip', window, cuePresTime + (1 - 0.5) * ifi);
        
        if trialNo < freeRewardTrials
            while((GetSecs()-vblStim)<stimRewardDelay)
                ;
            end

            if mod(rewardCounter,10) == 0
                earnedRewardVol = earnedRewardVol*rewardCompRate;
            end
            deliverReward(earnedRewardVol,syringeVol,rewardStepMotorCtl1);
            earnedRewardVolTotal = earnedRewardVolTotal + earnedRewardVol;
            if mod(rewardCounter,10) == 0
                earnedRewardVol = earnedRewardVol/rewardCompRate;
            end

            rewardCounter = rewardCounter + 1;
            
            rewardedTrial = 1;
            
        end
        
        
        
        
        initTime = GetSecs();
        [lickFlag, relDetectionTime] = detectLickOnRight(preferredStimDuration, spoutSession);
        lickDetectionTime = relDetectionTime + initTime;
        

        
        Screen('FillRect', window, gray);
        Screen('FillRect',window, black, patchRect);
        
        if lickFlag == 1
            hitCounter = hitCounter + 1;
            
            if trialNo > freeRewardTrials
                if mod(rewardCounter,10) == 0
                    earnedRewardVol = earnedRewardVol*rewardCompRate;
                end
                deliverReward(earnedRewardVol,syringeVol,rewardStepMotorCtl1);
                earnedRewardVolTotal = earnedRewardVolTotal + earnedRewardVol;
                if mod(rewardCounter,10) == 0
                    earnedRewardVol = earnedRewardVol/rewardCompRate;
                end
            
                rewardCounter = rewardCounter + 1;
            end
             
            disp(['Hit: ', num2str(hitCounter), ' / ', num2str(preferredStimCounter)]);
            disp(['passed time: ',num2str(floor((GetSecs()-startRecTime)/60)), ' Minuets']);
            
            vblAfterStimGrayTime = Screen('Flip', window, vblStim + (preferredStimFrames - 0.5) * ifi);
            trialDigitalTagSession.outputSingleScan(0);
            
            while((GetSecs - vblAfterStimGrayTime) < afterStimGrayTime)
                ;
            end
            
            rewardedTrial = 1;
            
%             if lickTrainDetectionTime < (vblStim + minStimDuration - afterRewardStimTime)
%                 vblAfterStimGrayTime = Screen('Flip', window, vblStim + (minStimFrames - 0.5) * ifi);  %fliping the screen back to gray after stimFrames
%             else
%                 vblAfterStimGrayTime = Screen('Flip', window, lickTrainDetectionTime + (afterRewardStimFrames - 0.5) * ifi);
%             end
%             while ((GetSecs - vblStim - relDetectionTime) < (relDetectionTime+afterStimGrayTime)) %waiting until screen turns to white
%                 ;
%             end
            
        else
            missedCounter = missedCounter + 1;
            
            
            disp(['Missed: ', num2str(missedCounter), ' / ', num2str(preferredStimCounter)]);
            disp(['passed time: ',num2str(floor((GetSecs()-startRecTime)/60)), ' Minuets']);
            
            vblAfterStimGrayTime = Screen('Flip', window, vblStim + (preferredStimFrames - 0.5) * ifi);
            trialDigitalTagSession.outputSingleScan(0);
            
            while((GetSecs - vblAfterStimGrayTime) < afterStimGrayTime)
                ;
            end

        end
        
        
    else
        
        NonPreferredStimCounter = NonPreferredStimCounter + 1;
        
        % this is the non preferred orientation
        Screen('DrawTextures', window, gabortex, [], righImageHorzPos+stimHeightOffset, orientationNonPreferred, [], [], [], [],...
            kPsychDontDoRotation, propertiesMat');
% 
%         Screen('DrawTextures', window, gabortex, [], righMirrorImageHorzPos+stimHeightOffset, orientationNonPreferred, [], [], [], [],...
%             kPsychDontDoRotation, propertiesMat');

        trialDigitalTagSession.outputSingleScan(1);
        [vblStim StimulusOnsetTime FlipTimestampStim MissedStim BeamposStim] = Screen('Flip', window, cuePresTime + (1 - 0.5) * ifi);
        
%         while((GetSecs()-vblStim)<stimRewardDelay)  %delay between stim start and reward deliver
%              ;
%         end
        
      
      
        initTime = GetSecs();
        [lickFlag, relDetectionTime] = detectLickOnRight(nonPreferredStimDuration, spoutSession);
        lickDetectionTime = relDetectionTime + initTime;
        

        Screen('FillRect', window, gray);
        Screen('FillRect',window, black, patchRect);
        
        
        if lickFlag == 1
            
            
            queueOutputData(soundOutputSession,cueSoundToNICard');
        
            soundOutputSession.startBackground;
            
            
%             Screen('FillRect', window, white);
%             Screen('FillRect',window, photoDiodeGray1, patchRect);
            
            falseAlarmCounter = falseAlarmCounter + 1;
            disp(['False Alarm: ', num2str(falseAlarmCounter), ' / ', num2str(NonPreferredStimCounter)]);
            disp(['passed time: ',num2str(floor((GetSecs()-startRecTime)/60)), ' Minuets']);
            
            vblAfterStimGrayTime = Screen('Flip', window, vblStim + (nonPreferredStimFrames - 0.5) * ifi);
            trialDigitalTagSession.outputSingleScan(0);
            wait(soundOutputSession);
            
            while((GetSecs - vblAfterStimGrayTime) < afterStimExtendedGrayTime)
                ;
            end 
            
            

        else
            
            

            correctRejectionCounter = correctRejectionCounter + 1;
            disp(['Correct Rejection: ', num2str(correctRejectionCounter), ' / ', num2str(NonPreferredStimCounter)]);
            disp(['passed time: ',num2str(floor((GetSecs()-startRecTime)/60)), ' Minuets']);
            
            vblAfterStimGrayTime = Screen('Flip', window, vblStim + (nonPreferredStimFrames - 0.5) * ifi);
            trialDigitalTagSession.outputSingleScan(0);
            while((GetSecs - vblAfterStimGrayTime) < afterStimGrayTime)
                ;
            end

        end
        
    end
    
    disp(' ');
    
    
    stimPresTime = [stimPresTime vblStim];

 
%     while((GetSecs - vblAfterStimGrayTime) < afterStimGrayTime)
%         ;
%     end
    
    
        
end 

sessionEndTime = now;

% Screen('FillRect', window, gray);  
% Screen('FillRect',window, black, patchRect);
% Screen('Flip', window);


% notification to the experimenter to enable trigger in camera setting to stop frame recording 
% if cameraRecordingEnable
%     cameraTriggerEnableDialogMirrorScreens;
% end


%Stop the recording
disp('Saving the session...')
pause(inputSavingDur) %To be sure that the whole session is recorded!

signalsRecordingSession.stop()

sca;
% Close the audio device
% PsychPortAudio('Close', pahandle);

delete(lh);
fclose(fid1);



%Saving the variables of the session and the code file in the recording
%directory
save(dataFolderAdd + '\' + 'workspaceVariables');
copyfile(string(mfilename('fullpath')) + '.m', dataFolderAdd);

disp(' ');

disp(['Hit: ', num2str(hitCounter), ' / ', num2str(preferredStimCounter)]);
disp(['Miss: ', num2str(missedCounter), ' / ', num2str(preferredStimCounter)]);
disp(' ');
disp(['Correct Rejection: ', num2str(correctRejectionCounter), ' / ', num2str(NonPreferredStimCounter)]);
disp(['False Alarm: ', num2str(falseAlarmCounter), ' / ', num2str(NonPreferredStimCounter)]);
disp(' ');
disp(['Total Reward: ', num2str(earnedRewardVolTotal)]);
disp(['Finish Time: ', datestr(sessionEndTime,'HH:MM:SS.FFF')])  
%reading the recorded data
fid2 = fopen(binFile,'r');
% testData = fread(fid2,'double');
[data,count] = fread(fid2,[7,inf],'double');
fclose(fid2);

figure()
t = data(1,:);
ch = data(2:7,:);

% temp = ch(1,:);
% temp(temp<4)=0;
% ch(1,:)=temp;

% temp = ch(5,:);
% temp(temp<4)=0;
% ch(5,:)=temp;


figure()
plot(t, ch);
% movegui('south');
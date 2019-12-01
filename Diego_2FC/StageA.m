clear all
close all 
  
Screen('Preference', 'SkipSyncTests', 1); 

% 2FC discrimination task;(one screen and two spouts), presenting
% the corresponding stimulus in each trial.
% STAGE A (amateur): The animal will receive a free reward 100 % of the time.

% Correct trials will be rewarded additionally doubling the amount of reward obtained for each correct trial.

mfilename('fullpath')
baseDirectory = 'Y:\recordedData\Behavioral\Diego';

if ~exist(baseDirectory, 'dir')
      baseDirectory = 'C:\recordedData\Behavioral\Diego'; 
end  
    
% entering the mouse Numbers, session duration and the session number of 
% the day  
prompt = {'Mouse number:','Trials Number','Session number:', 'Training stage (1-6)'}; 
titleBox = 'Stage A: 100% Free Rewards';
dims = [1 35]; 
dialogBoxInputs = inputdlg(prompt,titleBox,dims);
mouseNumber = dialogBoxInputs{1};
totalTrialNo = str2num(dialogBoxInputs{2});
sessionNumber = dialogBoxInputs{3};
stage = str2num(dialogBoxInputs{4});

if stage == 1
    
    FreeTrialProb = 1;
    StimTime = 3;
    NoLickTime = 4;
    PunishmentTime = 2;
    InterTrialInterval = 0;
    
elseif stage == 2
    
    FreeTrialProb = 0.8;
    StimTime = 2;
    NoLickTime = 4;
    PunishmentTime = 2;
    InterTrialInterval = 1;
    
elseif stage == 3
    
    FreeTrialProb = 0.5;
    StimTime = 2;
    NoLickTime = 4;
    PunishmentTime = 2;
    InterTrialInterval = 1;
    
elseif stage == 4
    
    FreeTrialProb = 0.3;
    StimTime = 2;
    NoLickTime = 5;
    PunishmentTime = 2;
    InterTrialInterval = 0;
    
elseif stage == 5
    
    FreeTrialProb = 0.1;
    StimTime = 2;
    NoLickTime = 5;
    PunishmentTime = 5;
    InterTrialInterval = 0;
    
elseif stage == 6
    
    FreeTrialProb = 0;
    StimTime = 2;
    NoLickTime = 5;
    PunishmentTime = 5;
    InterTrialInterval = 0;
    
end
    
% data folder name
dataFolderName = 'Mouse' + string(mouseNumber) + '_Stage-' + stage + '_' + datestr(date,'mm-dd-yyyy') + '_Session' + sessionNumber + '_' + mfilename;

%making the folder for saving the data
mkdir(baseDirectory,dataFolderName);
dataFolderAdd = string(baseDirectory) + '\' + dataFolderName;


niDevName = 'Dev1';
%Initialization of the required daq card sessions

%Analog input session for recording the following signals:
signalsRecordingSession = daq.createSession('ni');  
%1- output of the right lick sensor AI1
%2- copy of the right step motor command AI2
%3- output to the speaker AI3
%4- trial tags (sent through the daq card) AI5
%5- photodiode signal (sensed on the screens) AI0
%6- copy of the sound sent to the speaker AI4
%7- copy of the left lick sensor AI6
%8- copy of the left step motor command AI7

addAnalogInputChannel(signalsRecordingSession,niDevName,0,'Voltage');
addAnalogInputChannel(signalsRecordingSession,niDevName,1,'Voltage');
addAnalogInputChannel(signalsRecordingSession,niDevName,2,'Voltage');
addAnalogInputChannel(signalsRecordingSession,niDevName,3,'Voltage');
addAnalogInputChannel(signalsRecordingSession,niDevName,4,'Voltage');
addAnalogInputChannel(signalsRecordingSession,niDevName,5,'Voltage');
addAnalogInputChannel(signalsRecordingSession,niDevName,6,'Voltage');
addAnalogInputChannel(signalsRecordingSession,niDevName,7,'Voltage');
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

%left spout sensor
sensorCopyPortLine2 = 'port0/line3';
addDigitalChannel(spoutSession,niDevName,sensorCopyPortLine2,'InputOnly');
%p0/line0: a copy of the lick sensor output for the task managment

%lever sensor
% leverDigitalPortLine = 'port0/line5';
% addDigitalChannel(leverAndSpoutsSession,niDevName,leverDigitalPortLine,'InputOnly');



%Digital Output session for right reward control
rewardStepMotorCtl1 = daq.createSession('ni');
rewardPortLine1 = 'port0/line0';
%1 - output to step motor to control the reward
rewardStepMotorCtl1.addDigitalChannel(niDevName,rewardPortLine1,'OutputOnly');

%Digital Output session for left reward control
rewardStepMotorCtl2 = daq.createSession('ni');
rewardPortLine2 = 'port0/line4';
%1 - output to step motor to control the reward
rewardStepMotorCtl2.addDigitalChannel(niDevName,rewardPortLine2,'OutputOnly');
    
% Reward Volume:
earnedRewardVol = 8; %in microL
freeRewardVol = 5;
syringeVol = 5;

% enable recording the camera for the correct synchronization 
cameraRecordingEnable = 1;

%Stoping the code until the camera recording started
if cameraRecordingEnable
    cameraRecordingStartDialogMirrorScreens;
end


%Configuring the session for recording analog inputs
signalsRecordingSession.Rate = 3e3;
for chNo=1:size(signalsRecordingSession.Channels,2)
    signalsRecordingSession.Channels(1,chNo).TerminalConfig = 'SingleEnded';
end
signalsRecordingSession.IsNotifyWhenDataAvailableExceedsAuto = 0;
signalsRecordingSession.IsContinuous = true;
inputSavingDur = 1; %based on the warning, 0.05 seconds is the minimum saving time that is possible, (higher interval to less affect the timings in the code!)
signalsRecordingSession.NotifyWhenDataAvailableExceeds = signalsRecordingSession.Rate * inputSavingDur;

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

load C:\Users\Stimulation\Documents\MatlabScripts\AsusGammaTable23April2019SophiePhotometer
Screen('LoadNormalizedGammaTable', window, gammaTable*[1 1 1]);


% Define black and white (white will be 1 and black 0). This is because
% in general luminace values are defined between 0 and 1 with 255 steps in
% between. All values in Psychtoolbox are defined between 0 and 1
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Do a simply calculation to calculate the luminance value for grey. This
% will be half the luminace values for white
gray=(white+black)/2;


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
orientationRight = 0;
orientationLeft = 90;
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



%Stoping the code until the camera recording started
% if cameraRecordingEnable
%     cameraRecordingStartDialogMirrorScreens;
% end

% 
% Screen('FillRect', window, gray);
% Screen('FillRect',window, black, patchRect);
% Screen('Flip', window);

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

%--------------------------------------------------------------------------

% Stimulus Parameters
heightOffsetInCM = 0;
heightOffset = floor(heightOffsetInCM*pixelDensityCM);
widthOffset = 0;
 
stimHeightOffset = [0,heightOffset,0,gaborDimPixHeight+heightOffset];
righImageHorzPos = [0,0,gaborDimPixWidth,0];
% righMirrorImageHorzPos = [0,0,2*gaborDimPix,0];





  
stimDuration = StimTime; %in sec
stimFrames = round(stimDuration/ifi);

afterStimGrayTime = InterTrialInterval;
afterStimGrayFrames = round(afterStimGrayTime/ifi);

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
%Right side counters
RightStimCounter = 0;
RightHitCounter = 0;
RightWrongCounter = 0;
MissedRightCounter = 0;
RightEarnedTrialCounter = 0;
RightFreeTrialCounter = 0;
ConsecutiveIncorrectRightCounter = 0;

%Left side counters
LeftStimCounter = 0;
LeftHitCounter = 0;
LeftWrongCounter = 0;
MissedLeftCounter = 0;
LeftEarnedTrialCounter = 0;
LeftFreeTrialCounter = 0;
ConsecutiveIncorrectLeftCounter = 0;

FreeTrialCounter = 0;
EarnedTrialCounter =0;
FreeReward = 0;
pressFlag = 0;
IncorrectResponse = 0;

stimVector = [];
stimPresTime = [];
TrialOrientation = [];
RightTrials = [];
LeftTrials = [];
TrialType = [];
RightCumulativePerformance = []; % 0 for Free Reward, 1 for Contingent Reward
 LeftCumulativePerformance = [];

manualFinish = 0;
manualReward = 0;
oneSideStuck = 0;
earnedRewardVolTotal = 0;

rewardedTrial = 0;
previousSide = 0; %

rewardCounter = 1;

rewardCompRate = 1.25;

sameOrientation = 1;
maxSameOrientationNo = 2;

firstLicksSide = [];

KbWait;
startRecTime = GetSecs();

currentTrialOrientation = randi(2) - 1; % 1 is the preferred/rewarded Stim and 0 is non-rewarded
previousTrialOrientation = ~currentTrialOrientation;

goProb = 0.5; 
noLickDurBeforeStim = NoLickTime; % in sec


for trialNo=1:totalTrialNo
    
     
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
    %Check for keys:
%     Esc = Finish
%     P = Pause
%     C = Continue
%     R = Right reward+stim
%     L = Left Reward +stim
    
    if (find(keyCode) == 27)  %Press escape to manually finish the loop
        break;
    end
       
    if (find(keyCode) == 82)  %Press R to manually give a reward in right and force a right trial
        deliverReward(earnedRewardVol,syringeVol,rewardStepMotorCtl1); %RightReward;
        earnedRewardVolTotal = earnedRewardVolTotal + earnedRewardVol;
          
            currentTrialOrientation = 1; %Show Vertical gratings 
            
    elseif (find(keyCode) == 76)%Press L to manually give a reward in left and force a left trial
        
            deliverReward(earnedRewardVol,syringeVol,rewardStepMotorCtl2); %LeftReward
            earnedRewardVolTotal = earnedRewardVolTotal + earnedRewardVol;
            
            currentTrialOrientation = 0; %Show Horizontal grating
            
    end
        
%     if (LeftBiasCounter > RightHitCounter) | (RightBiasCounter > LeftHitCounter)
%         sameOrientation = 3;
%     end
    
    % Selection of trial orientation
    
    if sameOrientation >= maxSameOrientationNo 
        currentTrialOrientation = ~currentTrialOrientation;
    else
        if rand < goProb 
            currentTrialOrientation = 1; %Vertical (Right)
        else
            currentTrialOrientation = 0; % Horizontal (Left)
        end
    end
    
    if currentTrialOrientation == previousTrialOrientation
        sameOrientation = sameOrientation + 1;
    else
        sameOrientation = 1;
    end
    
    if IncorrectResponse
        currentTrialOrientation = previousTrialOrientation;
    end
    
    previousTrialOrientation = currentTrialOrientation;
    stimVector = [stimVector, currentTrialOrientation];
                
    phase = 360*rand;
    propertiesMat = [phase, freq, sigma, contrast, aspectRatio, 0, 0, 0];
    
    Screen('FillRect', window, gray);
    Screen('FillRect',window, white, patchRect);
    
   % 2 seconds of no licking between trials
    while (1)
        scanStartTime = GetSecs;
        [lickFlag, relDetectionTime] = detectLickOnRightOrLeft(noLickDurBeforeStim, spoutSession);
        if ~lickFlag
            break;
        end 
    end
    
    TrialRandomNumber = rand;
    
    if currentTrialOrientation %RIGHT TRIAL
        
        TrialOrientation = [TrialOrientation, 1];
        RightStimCounter = RightStimCounter + 1;
                      
        if ConsecutiveIncorrectRightCounter > 9
            deliverReward(freeRewardVol,syringeVol,rewardStepMotorCtl1);
            earnedRewardVolTotal = earnedRewardVolTotal + freeRewardVol;
            disp(['--Free Right Reward--']);
            FreeReward = FreeReward + 1;
        end
            
        
        % this is the Vertical-Right stimulus 
        Screen('DrawTextures', window, gabortex, [], righImageHorzPos+stimHeightOffset, orientationRight, [], [], [], [],...
            kPsychDontDoRotation, propertiesMat');

        [vblStim, StimulusOnsetTime, FlipTimestampStim, MissedStim, BeamposStim] = Screen('Flip', window, (1 - 0.5) * ifi);
        
        
        
        if TrialRandomNumber < FreeTrialProb
            
            TrialType = [TrialType, 0]; %Free Reward Trial
            disp(['Free Trial'])
            FreeTrialCounter = FreeTrialCounter + 1;
            RightFreeTrialCounter = RightFreeTrialCounter + 1;
            
            deliverReward(freeRewardVol,syringeVol,rewardStepMotorCtl1); %Right Free Reward
            earnedRewardVolTotal = earnedRewardVolTotal + freeRewardVol;
            rewardCounter = rewardCounter + 1;
        else
            TrialType = [TrialType, 1]; %Free Reward Trial
            disp(['Regular Trial'])
            EarnedTrialCounter = EarnedTrialCounter + 1;
            RightEarnedTrialCounter = RightEarnedTrialCounter + 1;
                       
        end
        
            Screen('FillRect', window, gray);
            Screen('FillRect',window, black, patchRect);
            
            initTime = GetSecs();
            [lickFlag, relDetectionTime] = detectLickOnRightOrLeft(stimDuration, spoutSession);
            lickDetectionTime = relDetectionTime + initTime;
                    
        if lickFlag == 1 %RIGHT::CORRECT                     

            RightHitCounter = RightHitCounter + 1;

            if TrialRandomNumber > FreeTrialProb
                deliverReward(earnedRewardVol,syringeVol,rewardStepMotorCtl1); %Right Earned Reward
                earnedRewardVolTotal = earnedRewardVolTotal + earnedRewardVol;
                rewardCounter = rewardCounter + 1;
            end

            disp(['HitRight: ', num2str(RightHitCounter), ' / ', num2str(RightStimCounter)]);
            disp(['passed time: ',num2str(floor((GetSecs()-startRecTime)/60)), ' Minutes']);

            vblAfterStimGrayTime = Screen('Flip', window, vblStim + (stimFrames - 0.5) * ifi);

            IncorrectResponse = 0;
            RightTrials = [RightTrials, 1];
            ConsecutiveIncorrectRightCounter = 0;

            while((GetSecs - vblAfterStimGrayTime) < afterStimGrayTime)
                ;
            end

        else %RIGHT::INCORRECT

            ConsecutiveIncorrectRightCounter = ConsecutiveIncorrectRightCounter + 1;
            IncorrectResponse = 1;

            if lickFlag == 2 % WRONG SIDE 

                RightWrongCounter = RightWrongCounter + 1;
                disp(['Wrong Side! L: ', num2str(RightWrongCounter), ' / ', num2str(RightStimCounter)]);
                disp(['passed time: ',num2str(floor((GetSecs()-startRecTime)/60)), ' Minutes']);
                RightTrials = [RightTrials, 2];
                vblAfterStimGrayTime = Screen('Flip', window, vblStim + (stimFrames - 0.5) * ifi);

                while((GetSecs - vblAfterStimGrayTime) < PunishmentTime)
                    ;
                end

            elseif lickFlag == 0 % MISS RIGHT                

                MissedRightCounter = MissedRightCounter + 1;

                disp(['MissedRight: ', num2str(MissedRightCounter), ' / ', num2str(RightStimCounter)]);
                disp(['passed time: ',num2str(floor((GetSecs()-startRecTime)/60)), ' Minutes']);
                RightTrials = [RightTrials, 0];
                vblAfterStimGrayTime = Screen('Flip', window, vblStim + (stimFrames - 0.5) * ifi);

                while((GetSecs - vblAfterStimGrayTime) < afterStimGrayTime)
                    ;
                end
            end
        end
        
                    
    else %LEFT TRIAL
        TrialOrientation = [TrialOrientation, 0];
       
        LeftStimCounter = LeftStimCounter + 1;
        EarnedTrialCounter = EarnedTrialCounter + 1;
        LeftEarnedTrialCounter = LeftEarnedTrialCounter + 1;
        
        if ConsecutiveIncorrectLeftCounter > 9
            deliverReward(freeRewardVol,syringeVol,rewardStepMotorCtl2);
            earnedRewardVolTotal = earnedRewardVolTotal + freeRewardVol;
            disp(['--Free Left Reward--']);
            FreeReward = FreeReward + 1;
        end
        
        % this is the Horizontal-Left stimulus
              
            Screen('DrawTextures', window, gabortex, [], righImageHorzPos+stimHeightOffset, orientationLeft, [], [], [], [],...
            kPsychDontDoRotation, propertiesMat');

        [vblStim StimulusOnsetTime FlipTimestampStim MissedStim BeamposStim] = Screen('Flip', window, (1 - 0.5) * ifi);
        
        if TrialRandomNumber < FreeTrialProb
            
            TrialType = [TrialType, 0]; %Free Reward Trial
            disp(['Free Trial'])
            FreeTrialCounter = FreeTrialCounter + 1;
            LeftFreeTrialCounter = LeftFreeTrialCounter + 1;                        
            deliverReward(freeRewardVol,syringeVol,rewardStepMotorCtl2); %Left Free Reward
            earnedRewardVolTotal = earnedRewardVolTotal + freeRewardVol;
            rewardCounter = rewardCounter + 1;
        else
            TrialType = [TrialType, 1]; %Earned Reward Trial
            disp(['Regular Trial'])
            EarnedTrialCounter = EarnedTrialCounter + 1;
            LeftFreeTrialCounter = LeftFreeTrialCounter + 1;
            
        end
            
        Screen('FillRect', window, gray);
        Screen('FillRect',window, black, patchRect);

        initTime = GetSecs();
        [lickFlag, relDetectionTime] = detectLickOnRightOrLeft(stimDuration, spoutSession);
        lickDetectionTime = relDetectionTime + initTime;

            if lickFlag == 2 %LEFT::CORRECT                     

                LeftHitCounter = LeftHitCounter + 1;
                                
                if TrialRandomNumber > FreeTrialProb
                                  
                deliverReward(earnedRewardVol,syringeVol,rewardStepMotorCtl2); %Left Earned Reward
                earnedRewardVolTotal = earnedRewardVolTotal + earnedRewardVol;
                rewardCounter = rewardCounter + 1;
                
                end

                disp(['HitLeft: ', num2str(LeftHitCounter), ' / ', num2str(LeftStimCounter)]);
                disp(['passed time: ',num2str(floor((GetSecs()-startRecTime)/60)), ' Minutes']);

                vblAfterStimGrayTime = Screen('Flip', window, vblStim + (stimFrames - 0.5) * ifi);

                IncorrectResponse = 0;
                LeftTrials = [LeftTrials, 1];
                ConsecutiveIncorrectLeftCounter = 0;

                while((GetSecs - vblAfterStimGrayTime) < afterStimGrayTime)
                    ;
                end

            else %FREE LEFT::INCORRECT

                ConsecutiveIncorrectLeftCounter = ConsecutiveIncorrectLeftCounter + 1;
                IncorrectResponse = 1;

                if lickFlag == 1 % FREE WRONG SIDE 

                    LeftWrongCounter = LeftWrongCounter + 1;
                    disp(['Wrong Side! R: ', num2str(LeftWrongCounter), ' / ', num2str(LeftStimCounter)]);
                    disp(['passed time: ',num2str(floor((GetSecs()-startRecTime)/60)), ' Minutes']);
                    LeftTrials = [LeftTrials, 2];
                    vblAfterStimGrayTime = Screen('Flip', window, vblStim + (stimFrames - 0.5) * ifi);

                    while((GetSecs - vblAfterStimGrayTime) < PunishmentTime)
                        ;
                    end

                elseif lickFlag == 0 % FREE MISS LEFT                

                    MissedLeftCounter = MissedLeftCounter + 1;

                    disp(['MissedLeft: ', num2str(MissedLeftCounter), ' / ', num2str(LeftStimCounter)]);
                    disp(['passed time: ',num2str(floor((GetSecs()-startRecTime)/60)), ' Minutes']);
                    LeftTrials = [LeftTrials, 0];
                    vblAfterStimGrayTime = Screen('Flip', window, vblStim + (stimFrames - 0.5) * ifi);

                    while((GetSecs - vblAfterStimGrayTime) < afterStimGrayTime)
                        ;
                    end
                end
            end
            
    end
    RightTrialPerformance = (RightHitCounter - RightWrongCounter)/(RightHitCounter + RightWrongCounter);
    RightCumulativePerformance = [RightCumulativePerformance, RightTrialPerformance];
    disp(['Right Performance: ',num2str(RightTrialPerformance*100),'%']);
    LeftTrialPerformance = (LeftHitCounter - LeftWrongCounter)/(LeftHitCounter + LeftWrongCounter);
    LeftCumulativePerformance = [LeftCumulativePerformance, LeftTrialPerformance];
    disp(['Left Performance: ',num2str(LeftTrialPerformance*100),'%']);
       
    disp(' ');
    
    stimPresTime = [stimPresTime vblStim];

        
end 

sessionEndTime = now;

% Screen('FillRect', window, gray);  
% Screen('FillRect',window, black, patchRect);
% Screen('Flip', window);


% notification to the experimenter to enable trigger in camera setting to stop frame recording 
if cameraRecordingEnable
    cameraTriggerEnableDialogMirrorScreens;
end


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
disp(['Stage-', num2str(stage)]);
disp(['Free trials:', num2str(FreeTrialCounter), '(', num2str(FreeTrialProb), ')']);
disp(['Stimulus Time:', num2str(StimTime), ' No Lick Time:', num2str(NoLickTime)]);
disp(['Punishment:', num2str(PunishmentTime), ' ISI:', num2str(InterTrialInterval)]);   
disp(' ');
disp(['HitRight: ', num2str(RightHitCounter), ' / ', num2str(RightStimCounter)]);
disp(['MissRight: ', num2str(MissedRightCounter), ' / ', num2str(RightStimCounter)]);
disp(['WrongRight: ', num2str(RightWrongCounter), ' / ', num2str(RightStimCounter)]);
disp(' ');
disp(['HitLeft: ', num2str(LeftHitCounter), ' / ', num2str(LeftStimCounter)]);
disp(['MissLeft: ', num2str(MissedLeftCounter), ' / ', num2str(LeftStimCounter)]);
disp(['WrongLeft: ', num2str(LeftWrongCounter), ' / ', num2str(LeftStimCounter)]);
disp(' ');
disp(['Total Reward: ', num2str(earnedRewardVolTotal)]);
disp(['Finish Time: ', datestr(sessionEndTime,'HH:MM:SS.FFF')])  
%reading the recorded data
fid2 = fopen(binFile,'r');
% testData = fread(fid2,'double');
[data,count] = fread(fid2,[6,inf],'double');
fclose(fid2);

% figure()
% t = data(1,:);
% ch = data(2:6,:);
% 
% temp = ch(1,:);
% temp(temp<4)=0;
% ch(1,:)=temp;
% 
% % temp = ch(5,:);
% % temp(temp<4)=0;
% % ch(5,:)=temp;
% 
% 
% figure()
% plot(t, ch);
% movegui('south');
clear all
close all 

niDevName = 'Dev1';

samplingFreq = 5e3;





% niDevName = 'Dev2';
soundOutputSession = daq.createSession('ni');  

addAnalogOutputChannel(soundOutputSession,niDevName,0,'Voltage');
soundOutputSession.Rate = samplingFreq;

cueSoundDur = 0.2;
% cueSoundDurFrames = round(cueSoundDur/ifi);
% samplingFreq = 100e3;
cueSoundFreq = 2400;
cueSoundAmp = 0.1;
      
tCue = 0:1/samplingFreq:cueSoundDur;
cueSoundToNICard = cueSoundAmp*sin(2*pi*cueSoundFreq*tCue);


queueOutputData(soundOutputSession,cueSoundToNICard');
        
soundOutputSession.startBackground;

wait(soundOutputSession);

punishmentSoundAmp = 0.2;
punishmentSoundDur = 0.5;
freqChangeDur = 0.05;
numberOfIndividualDurs = floor(punishmentSoundDur/freqChangeDur);

tPunishment = 0:1/samplingFreq:punishmentSoundDur;

randomFreqVec = (randi(12,1,numberOfIndividualDurs)/5)*1e3;
punishmentSound = zeros(size(tPunishment));

for freqNo=1:numberOfIndividualDurs

    tIndividualDur = tPunishment(floor(1+(freqNo-1)*samplingFreq*freqChangeDur):floor(freqNo*freqChangeDur*samplingFreq));

    punishmentSound(floor(1+(freqNo-1)*samplingFreq*freqChangeDur):floor(freqNo*freqChangeDur*samplingFreq)) = (square(2*pi*randomFreqVec(freqNo)*tIndividualDur)+1)/2;
end

punishmentSoundToNICard = punishmentSoundAmp*2*(punishmentSound - 0.5);

queueOutputData(soundOutputSession,punishmentSoundToNICard');
        
soundOutputSession.startBackground;

wait(soundOutputSession);
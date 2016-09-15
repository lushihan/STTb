% wipe clean
clear all; clc; close all;

% Load toolkit
addpath('toolkit/');
setupToolkit(0);

%
% Creates user test samples that use synthesis.
%

outputFolder = '~/Temp/usertest/output/';

%% Load parameters
analysis_parameters;
synthesis_parameters;

synthParams.nIterations = 30;

imposeParams = synthParams.impose;
imposeParams.modPower = 0;
imposeParams.modC1 = 1;
imposeParams.modC1Analytic = 0;
imposeParams.modC2 = 1;
imposeParams.modC2Amp = 0;
synthParams.impose = imposeParams;

%% Load stats
statsFolder = '~/Temp/usertest/stats/';

files = {...
    'rain', 'train', 'bees', 'wind', 'drills' ... % 5
    'applause', 'bubbles', 'babble', 'stream', 'fire', ... % 10
    'swamp', 'gravel', 'helicopter', 'glass_chimes', 'windchimes', ... % 15
    'glass_shards', 'tuning', 'violin', 'scary', 'scary2', ... % 20
    'guitar_sample', 'guitar_clean_1', 'guitar_clean_2', 'guitar_dist_2', 'guitar_dist_3'... % 25
    'ride_low', 'ride_hi', 'drumroll_1', 'drumroll_2', 'purring', ...
    };
nFiles = length(files);

for iFile = nFiles,
disp( ['Loading stats for ' files{iFile}] );

load([statsFolder files{iFile} '.mat']);

% create output parameter struct
outputParams.desiredRMS = .05;

% Get constants
audio_sr = analysisParams.audio_sr;
env_sr = analysisParams.env_sr;

nSamples = audio_sr * analysisParams.modspectra.block;
nFrames = env_sr * analysisParams.modspectra.block;

% Generate filterbanks
filterBundle = generateFilterBundle( analysisParams, nSamples, nFrames );

% Initialize samples
synthSound = randn(nSamples, 1); % create Gaussian noise signal

% Synthesize residuals
synthResiduals = synthesizeResiduals( synthSound, ...
    stats.residual.coeffs, filterBundle, analysisParams.compression );

% Synthesize envelopes
[synthEnvs, snrs] = synthesizeEnvelopes( synthSound, ...
    stats, synthParams, analysisParams, filterBundle );


%% Full synthesis

% merge residual and envelopes
synthSubbands = restoreSubbands( synthEnvs, synthResiduals, ...
    filterBundle.window, analysisParams.compression );

% equalize subbands
synthSubbandsAdj = adjustSubbands( synthSubbands, stats.subbandVars );

% merge subbands
x = collapseSubbands( synthSubbandsAdj, filterBundle.audioFilters );
x = x/rms(x) * outputParams.desiredRMS;
outFile = [files{iFile} '_old_phase' '.wav'];

writeAudioFile( x, audio_sr, [outputFolder outFile] );
disp(['Saved ' outFile]);

%% Save SNR information to file
snrFile = [outputFolder files{iFile} '_snrs_old.csv'];
fid = fopen(snrFile, 'w');

params = {'modC1', 'modC1Analytic', 'modC2', 'modC2Amp'};
nParams = length(params);

% header
fprintf(fid, 'iteration, ');
for iParam = 1:nParams,
    if eval(['synthParams.impose.' params{iParam}]),
        fprintf(fid, [params{iParam}]);
        
        if iParam < nParams,
            fprintf(fid, ', ');
        end
    end
end
fprintf(fid, '\n');

for iIterations = 1:synthParams.nIterations,
    
    fprintf(fid, [num2str(iIterations) ', ']);    
    
    for iParam = 1:nParams,
    
        if eval(['synthParams.impose.' params{iParam}]),
            value = eval(['snrs{iIterations}.' params{iParam}]);
            fprintf(fid, num2str(value));
            
            if iParam < nParams,
                fprintf(fid, ', ');
            end
        end
    end
    fprintf(fid, '\n');
end

fclose(fid);
end
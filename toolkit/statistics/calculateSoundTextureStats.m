function stats = calculateSoundTextureStats( subbandEnvs, residuals, ...
    modbands, modbandsC2, analysisParams )

%
% Residuals
%
[a, g] = lpc( residuals, analysisParams.residual.lpcOrder );
stats.residual.coeffs = a;
stats.residual.gain = g;


%
% Modulation Spectrum Amplitude
%
stats.modSpectraAmps = calculateModSpecAmps( subbandEnvs, ...
    analysisParams.env_sr, analysisParams.modspectra ); 


%
% Between subband (C1) modulation correlations
%

% Analytic signal correlation
stats.modC1Analytic = calculateModC1AnalyticStatsFull( modbands );


%
% Within subband (C2) modulation correlations
%

% C2 correlation
stats.modC2 = calculateModC2StatsFull( modbandsC2 );
% C2 amplitude correlation
stats.modC2Amp = calculateModC2AmpFull( modbands );
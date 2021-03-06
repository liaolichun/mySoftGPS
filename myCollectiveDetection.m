function [collectiveCorrelogram count] = myCollectiveDetection(roughEstimate, satPositions, satClkCorr, results, eph, settings, acqResults)

% This function is a fast version of collective detection. It finds out the
% correct clock-bias for each satellite and uses these candidates for
% projection in the search domain.

% The number of projections from code phase - Doppler domain to space -
% time doain are equal to the number of satellites in view.

% Initialize the big correlogram matrix to speed up operations:
collectiveCorrelogram = zeros(2 * (roughEstimate.uncertaintyN / roughEstimate.stepN) + 1, 2 * (roughEstimate.uncertaintyE / roughEstimate.stepE) + 1, ...
                              2 * (roughEstimate.uncertaintyU / roughEstimate.stepU) + 1, 2 * (roughEstimate.uncertaintyClockBias / roughEstimate.stepB) + 1);

% Initialize index variables:
indexN = 1;
indexE = 1;
indexU = 1;
count = 0;
samplesPerCode = round(settings.samplingFreq / (settings.codeFreqBasis / settings.codeLength));

% Loop over all possible northing steps:
for N = roughEstimate.N - roughEstimate.uncertaintyN : roughEstimate.stepN : roughEstimate.N + roughEstimate.uncertaintyN
    
    % Loop over all possible easting steps:
    for E = roughEstimate.E - roughEstimate.uncertaintyE : roughEstimate.stepE : roughEstimate.E + roughEstimate.uncertaintyE
        
        % Loop over all possible height steps:
        for U = roughEstimate.U - roughEstimate.uncertaintyU : roughEstimate.stepU : roughEstimate.U + roughEstimate.uncertaintyU
            
            % Loop over all visible satellites:
            for satNr = 1 : length(eph.PRN)
                
                % Calculate actual range without the clock-bias:
                rangeMS = calculateRangeMS(N, E, U, satPositions(:, satNr), satClkCorr(satNr), settings);
                
                % This gives the code-phase without clock-bias:
                predictedCodePhase = round(mod(rangeMS, 1) * samplesPerCode);
                
                % So the rest of the shift should come from clock bias.
                % To take care of the overflow of mod(code-phase, 1ms) we
                % will get 4 cases:
                if acqResults.codePhase(eph.PRN(satNr)) - predictedCodePhase > 0 && acqResults.codePhase(eph.PRN(satNr)) - predictedCodePhase < samplesPerCode / 2
                    possibleB = acqResults.codePhase(eph.PRN(satNr)) - predictedCodePhase;
                elseif acqResults.codePhase(eph.PRN(satNr)) - predictedCodePhase > 0 && acqResults.codePhase(eph.PRN(satNr)) - predictedCodePhase > samplesPerCode / 2
                    possibleB = -(predictedCodePhase + (samplesPerCode - acqResults.codePhase(eph.PRN(satNr))));
                elseif acqResults.codePhase(eph.PRN(satNr)) - predictedCodePhase < 0 && predictedCodePhase - acqResults.codePhase(eph.PRN(satNr)) > samplesPerCode / 2
                    possibleB = acqResults.codePhase(eph.PRN(satNr)) + (samplesPerCode - predictedCodePhase);
                elseif acqResults.codePhase(eph.PRN(satNr)) - predictedCodePhase < 0 && predictedCodePhase - acqResults.codePhase(eph.PRN(satNr)) < samplesPerCode / 2
                    possibleB = acqResults.codePhase(eph.PRN(satNr)) - predictedCodePhase;
                end
                
                % Clock-bias in meters:
                possibleB = (possibleB/samplesPerCode) * 300000;
                
                % The index of clock-bias in terms of step-size.
                % For example, if search range of clock-bias is from
                % -150000 to +150000 meters in steps of 150 meters, and 
                % clock-bias is 50 meters, then it will fall in the bin
                % number 1001:
                if possibleB - (roughEstimate.clockBias - roughEstimate.uncertaintyClockBias) < 0
                    indexB = ceil((possibleB - (roughEstimate.clockBias - roughEstimate.uncertaintyClockBias))/roughEstimate.stepB);
                else
                    indexB = ceil((possibleB - (roughEstimate.clockBias - roughEstimate.uncertaintyClockBias))/roughEstimate.stepB) + 1;
                end
                
                % "Quantized" clock-bias in meters:
                B = roughEstimate.clockBias - roughEstimate.uncertaintyClockBias + (indexB - 1) * roughEstimate.stepB;
                
                % Now, projecting the correlators, same as in the normal
                % case:
                for CCPRN = 1 : length(eph.PRN)
                    
                    count = count + 1;
                    
                    pseudoRangeMS = calculatePseudorangeMS(N, E, U, B, satPositions(:, CCPRN), satClkCorr(CCPRN), settings);
                    
                    codePhase = round(mod(pseudoRangeMS, 1) * samplesPerCode);
                    
                    if codePhase == 0
                        codePhase = 1;
                    end
                    
                    collectiveCorrelogram(indexN, indexE, indexU, indexB) = collectiveCorrelogram(indexN, indexE, indexU, indexB) + ...
                                                                                                                   max(results(eph.PRN(CCPRN), :, codePhase));
                    
                end % for CCPRN = 1 : length(eph.PRN)
                
            end % for satNr = 1 : length(eph.PRN)
            indexU = indexU + 1;
        end
        indexE = indexE + 1;
        indexU = 1;
    end
    indexN = indexN + 1;
    indexE = 1;
    indexU = 1;
end
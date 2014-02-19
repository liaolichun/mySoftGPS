function [roughEstimate] = myAiding()

% This function returns a struct with information provided apriori.

% Latitude:
roughEstimate.lat = 51.005011445;

% Longitude:
roughEstimate.long = -113.991569502;

% Height:
roughEstimate.ht = 1160.224;

% Convert to northing, easting and up:
[roughEstimate.E roughEstimate.N] = deg2utm(roughEstimate.lat, roughEstimate.long);
roughEstimate.U = roughEstimate.ht;

% Clock bias estimate should be zero initially, because we have no idea about it:
roughEstimate.clockBias = 0;

% Uncertainty in rough estimate:
roughEstimate.uncertaintyU = 0;
roughEstimate.uncertaintyE = 100;
roughEstimate.uncertaintyN = 100;
roughEstimate.uncertaintyClockBias = 150000;

% Step size in all four dimensions:
roughEstimate.stepN = 10;
roughEstimate.stepE = 10;
roughEstimate.stepU = 1;
roughEstimate.stepB = 150;
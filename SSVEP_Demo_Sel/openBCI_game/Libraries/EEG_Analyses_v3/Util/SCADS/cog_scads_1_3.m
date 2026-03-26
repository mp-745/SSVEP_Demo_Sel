function rejectSensors = cog_scads_1_3(paraMat, lambda)
    medSensor = nanmedian(paraMat, 2);
    grandMed = nanmedian(medSensor);

    limit = lambda*rms(medSensor - grandMed);
    lowerBound = grandMed - limit;
    upperBound = grandMed + limit;
    
    rejectSensors = find(medSensor < lowerBound | medSensor > upperBound);
end
function rejectTrials = cog_scads_1_4(paraMat, mu)
    medSensor = nanmedian(paraMat, 2);
    for i = 1:size(paraMat,1)
        limit(i) = mu*rms(paraMat(i,:) - medSensor(i));
        lb(i) = medSensor(i) - limit(i);
        ub(i) = medSensor(i) + limit(i);
    end
    for i = 1:size(paraMat,1)
        rejectTrials{i} = find(paraMat(i,:) < lb(i) | paraMat(i,:) > ub(i));
    end
%     keyboard;
end
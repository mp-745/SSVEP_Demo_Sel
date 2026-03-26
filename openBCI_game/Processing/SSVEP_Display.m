function SSVEP_Display()

    % ---------------- STATE ----------------
    knobIndex = 1;
    nTicks = 8;
    instruments = {'Beat 1','Beat 2','Beat 3','Beat 4','Beat 5','Beat 6','Beat 7','Beat 8'};

    % ---------------- FIGURE ----------------
    fig = figure('Color','k','Name','SSVEP Music BCI');
    axis equal off;
    hold on;

    % ---------------- KNOB ----------------
    theta = linspace(0,2*pi,200);
    plot(cos(theta), sin(theta), 'w','LineWidth',2);

    tickAngles = linspace(0,2*pi,nTicks+1);
    tickAngles(end) = [];

    for i = 1:nTicks
        plot([0.9*cos(tickAngles(i)) cos(tickAngles(i))], ...
             [0.9*sin(tickAngles(i)) sin(tickAngles(i))],'w');
    end

    pointer = plot([0 0],[0 0.8],'r','LineWidth',3);

    % ---------------- TEXT ----------------
    textHandles = gobjects(nTicks,1);
    for i = 1:nTicks
        textHandles(i) = text(1.4*cos(tickAngles(i)), ...
                              1.4*sin(tickAngles(i)), ...
                              instruments{i}, ...
                              'Color','w', ...
                              'FontSize',10, ...
                              'FontWeight','normal', ...
                              'HorizontalAlignment','center');
    end

    % ---------------- CALLBACK ----------------
    function decisionHandler(decision)

        if decision == 1
            % %%% ROTATE KNOB
            knobIndex = mod(knobIndex, nTicks) + 1;

            set(pointer,'XData',[0 0.8*cos(tickAngles(knobIndex))], ...
                        'YData',[0 0.8*sin(tickAngles(knobIndex))]);

        elseif decision == 2
            % %%% CONFIRM SELECTION
            for i = 1:nTicks
                set(textHandles(i),'FontSize',10,'FontWeight','normal');
            end
            set(textHandles(knobIndex),'FontSize',16,'FontWeight','bold');
        end

        drawnow limitrate;  % %%% CHANGED: non-blocking redraw
    end

    % ---------------- LOAD CLASSIFIER ----------------
    load('SSVEP_SVM_Model.mat');

    % ---------------- START REALTIME ----------------
    realtimeDecisionDemo( ...
        'C:\Users\maxpo\OneDrive\Documents\gtec\Unicorn Suite\Hybrid Black\Unicorn Recorder\Sample data\15 Hz\UnicornRecorder_16_01_2026_16_24_340.csv', ...
        SVMModel, 250, [6 7 8], [15 20], [], ...
        round(250*2), round(250*0.25), hann(round(250*2))', ...
        @decisionHandler );   % %%% CHANGED
end


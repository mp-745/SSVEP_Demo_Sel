function updateFcn = SSVEP_Display_Fig()
%% SSVEP KNOB DISPLAY — Standard MATLAB Figure (No Psychtoolbox needed)
% Returns a function handle updateFcn(BCI_input) that BCI_main can call
% to update the knob display.
%   BCI_input = 0 → rotate knob
%   BCI_input = 1 → confirm selection
%
% Includes two flickering SSVEP stimulus circles (15 Hz left, 20 Hz right)
% driven by a MATLAB timer at ~60 Hz.

    % --- State ---
    knobIndex = 1;
    nTicks = 8;
    instruments = {'Beat 1','Beat 2','Beat 3','Beat 4', ...
                   'Beat 5','Beat 6','Beat 7','Beat 8'};

    % --- SSVEP flicker frequencies ---
    flickerFreqL = 15;  % Hz (left stimulus)
    flickerFreqR = 20;  % Hz (right stimulus)
    t0 = tic;           % reference time for flicker

    % --- Figure ---
    fig = figure('Color','k', 'Name','SSVEP Music BCI', ...
                 'NumberTitle','off', 'MenuBar','none', ...
                 'Position',[100 100 900 900], ...
                 'DeleteFcn', @onClose);
    ax = axes('Parent',fig, 'Color','k', 'XColor','none','YColor','none');
    axis equal off;
    hold on;
    xlim([-2.5 2.5]); ylim([-2.5 2.5]);

    % --- Title ---
    text(0, 2.1, 'DRUMS', 'Color','w', 'FontSize',32, 'FontWeight','bold', ...
         'HorizontalAlignment','center', 'Parent',ax);

    % --- Knob circle ---
    theta = linspace(0, 2*pi, 200);
    plot(ax, cos(theta), sin(theta), 'w', 'LineWidth', 2);

    % --- Tick marks and labels ---
    tickAngles = linspace(0, 2*pi, nTicks+1);
    tickAngles(end) = [];

    for i = 1:nTicks
        plot(ax, [0.9*cos(tickAngles(i)) cos(tickAngles(i))], ...
                 [0.9*sin(tickAngles(i)) sin(tickAngles(i))], 'w', 'LineWidth', 2);
    end

    textHandles = gobjects(nTicks, 1);
    for i = 1:nTicks
        textHandles(i) = text(1.4*cos(tickAngles(i)), ...
                               1.4*sin(tickAngles(i)), ...
                               instruments{i}, ...
                               'Color','w', 'FontSize',12, ...
                               'FontWeight','normal', ...
                               'HorizontalAlignment','center', ...
                               'Parent',ax);
    end

    % --- Pointer ---
    pointer = plot(ax, [0 0.8*cos(tickAngles(1))], ...
                       [0 0.8*sin(tickAngles(1))], ...
                       'r', 'LineWidth', 4);

    % --- SSVEP Flickering Stimuli ---
    % Left circle (15 Hz) — bottom-left
    circTheta = linspace(0, 2*pi, 60);
    circR = 0.35;
    leftX = -1.8; leftY = -1.8;
    leftCircle = fill(ax, leftX + circR*cos(circTheta), ...
                          leftY + circR*sin(circTheta), ...
                          'w', 'EdgeColor','none');
    text(leftX, leftY - 0.55, sprintf('%d Hz', flickerFreqL), ...
         'Color','w', 'FontSize',11, 'HorizontalAlignment','center', 'Parent',ax);
    text(leftX, leftY - 0.75, 'ROTATE', ...
         'Color',[0.5 0.5 0.5], 'FontSize',9, 'HorizontalAlignment','center', 'Parent',ax);

    % Right circle (20 Hz) — bottom-right
    rightX = 1.8; rightY = -1.8;
    rightCircle = fill(ax, rightX + circR*cos(circTheta), ...
                           rightY + circR*sin(circTheta), ...
                           'w', 'EdgeColor','none');
    text(rightX, rightY - 0.55, sprintf('%d Hz', flickerFreqR), ...
         'Color','w', 'FontSize',11, 'HorizontalAlignment','center', 'Parent',ax);
    text(rightX, rightY - 0.75, 'SELECT', ...
         'Color',[0.5 0.5 0.5], 'FontSize',9, 'HorizontalAlignment','center', 'Parent',ax);

    % --- Status text ---
    statusText = text(0, -2.2, 'Waiting for BCI input...', ...
                      'Color','g', 'FontSize',14, ...
                      'HorizontalAlignment','center', 'Parent',ax);

    drawnow;

    % --- Flicker Timer (~60 Hz) ---
    flickerTimer = timer('ExecutionMode','fixedRate', ...
                         'Period', round(1/60, 3), ...
                         'TimerFcn', @flickerCallback);
    start(flickerTimer);

    % --- Return the update function ---
    updateFcn = @updateKnob;

    % ===================== NESTED FUNCTIONS =====================

    function flickerCallback(~, ~)
        if ~ishandle(fig), return; end

        elapsed = toc(t0);

        % Left circle: ON for half-cycle, OFF for half-cycle
        leftOn = mod(floor(elapsed * flickerFreqL * 2), 2) == 0;
        if leftOn
            set(leftCircle, 'FaceColor','w', 'FaceAlpha',1);
        else
            set(leftCircle, 'FaceColor','k', 'FaceAlpha',1);
        end

        % Right circle: same logic at different frequency
        rightOn = mod(floor(elapsed * flickerFreqR * 2), 2) == 0;
        if rightOn
            set(rightCircle, 'FaceColor','w', 'FaceAlpha',1);
        else
            set(rightCircle, 'FaceColor','k', 'FaceAlpha',1);
        end

        drawnow limitrate;
    end

    function updateKnob(BCI_input)
        if ~ishandle(fig), return; end

        if BCI_input == 0
            % ROTATE KNOB
            knobIndex = mod(knobIndex, nTicks) + 1;
            set(pointer, 'XData', [0 0.8*cos(tickAngles(knobIndex))], ...
                         'YData', [0 0.8*sin(tickAngles(knobIndex))]);

            % Reset all labels to normal
            for j = 1:nTicks
                set(textHandles(j), 'FontSize',12, 'FontWeight','normal', 'Color','w');
            end
            % Highlight current
            set(textHandles(knobIndex), 'FontSize',16, 'FontWeight','bold', 'Color','y');
            set(statusText, 'String', sprintf('Pointing at: %s', instruments{knobIndex}));

        elseif BCI_input == 1
            % CONFIRM SELECTION
            for j = 1:nTicks
                set(textHandles(j), 'FontSize',12, 'FontWeight','normal', 'Color','w');
            end
            set(textHandles(knobIndex), 'FontSize',18, 'FontWeight','bold', 'Color','g');
            set(statusText, 'String', sprintf('SELECTED: %s', instruments{knobIndex}));
        end

        drawnow limitrate;
    end

    function onClose(~, ~)
        % Clean up the flicker timer when figure is closed
        if isvalid(flickerTimer)
            stop(flickerTimer);
            delete(flickerTimer);
        end
    end
end

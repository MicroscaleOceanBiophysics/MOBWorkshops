data = readtable('test_NPQ.RPT', FileType='text')

colors   = {'#1f77b4', '#2ca02c', '#ff7f0e', '#8B0000'};
markers  = {'x', 'd', 'x', 'o'};
mfcolors = colors;

labels = { ...
    '\lambda_1 = 470 nm', ...
    '\lambda_2 = 520 nm', ...
    '\lambda_3 = 645 nm', ...
    '\lambda_4 = 665 nm'};

mfcolors{4} = 'none';

% Conversion temps HH:MM:SS -> secondes
sec_ = @(s) sscanf(s, '%d:%d:%d')' * [3600; 60; 1];

% Temps complet
time_all = zeros(height(data),1);
for i = 1:height(data)
    time_all(i) = sec_(char(data.Time(i)));
end

figs_NPQ = gobjects(4,1);

keys = {'AllOpePSII', 'opePSII', 'maxPSII', 'NPQEstim'};

for i = 1:length(keys)

    k = keys{i};

    figs_NPQ(i) = figure;
    ax = axes;
    hold(ax, 'on');

    for ch = 1:4

        c   = colors{ch};
        m   = markers{ch};
        mfc = mfcolors{ch};
        lbl = labels{ch};

        chs = num2str(ch);

        time = time_all;
        time0 = time(1);

        % Colonnes dynamiques
        Fm = data.(sprintf('Fm%s', chs));
        F  = data.(sprintf('F%s', chs));

        if strcmp(k, 'AllOpePSII')
            Y = (Fm - F) ./ Fm;
        end

        % Données sous lumière actinique
        idx_AL = data.PAR > 16;
        data_AL = data(idx_AL,:);

        if ~strcmp(k, 'AllOpePSII')

            time = zeros(height(data_AL),1);

            for t = 1:height(data_AL)
                time(t) = sec_(char(data_AL.Time(t)));
            end

            fm = data_AL.(sprintf('Fm%s', chs));
            f  = data_AL.(sprintf('F%s', chs));

            fq = fm - f;

            if strcmp(k, 'opePSII')
                Y = fq ./ fm;
            end

            % Ligne suivante après chaque mesure AL
            idx = find(idx_AL);
            idx_next = idx + 1;
            idx_next(idx_next > height(data)) = [];

            data_0 = data(idx_next,:);

            f0_star  = data_0.(sprintf('F%s', chs));
            f0m_star = data_0.(sprintf('Fm%s', chs));

            % Adapter longueur si nécessaire
            n = min([length(f0_star), length(fm)]);

            f0_star  = f0_star(1:n);
            f0m_star = f0m_star(1:n);
            fm2      = fm(1:n);

            f0 = 1 ./ (1 ./ f0_star - 1 ./ f0m_star + 1 ./ fm2);

            fv = fm2 - f0;

            if strcmp(k, 'maxPSII')
                Y = fv ./ fm2;
            end

            % Données dark adapted
            idx_first_AL = find(idx_AL,1,'first');
            data_DA = data(1:idx_first_AL-1,:);

            fm_DA = data_DA.(sprintf('Fm%s', chs));
            fm_DA = fm_DA(end);

            if strcmp(k, 'NPQEstim')
                Y = (fm_DA - fm2) ./ fm2;
            end
        end

        % Valeurs négatives -> NaN
        Y(Y < 0) = NaN;

        plot((time - time0)/60, Y, ...
            'LineStyle', 'none', ...
            'Marker', m, ...
            'Color', c, ...
            'MarkerFaceColor', mfc, ...
            'DisplayName', lbl);
    end

    xlabel('Time / min');

    if strcmp(k, 'AllOpePSII')
        ylabel('Yield');
    end

    if strcmp(k, 'opePSII')
        ylabel({'PSII operating efficiency', ...
            'K_P''[Q_A]'' / (K_F + K_{NPQ}'' + K_P''[Q_A]'')'});
    end

    if strcmp(k, 'maxPSII')
        ylabel({'PSII maximal efficiency', ...
            'K_P'' / (K_F + K_{NPQ}'' + K_P'')'});
    end

    if strcmp(k, 'NPQEstim')
        ylabel('NPQ: (K_{NPQ}'' - K_{NPQ}) / K_{NPQ}');
    end

    legend('show');

    % Axe secondaire PAR
    ax.Box = 'off';
    yyaxis right

    time2 = repelem(time_all, 2);
    time2 = [time2(1)-20 ; time2];

    PAR = repelem(data.PAR, 2);

    plot((time2(1:end-1) - time2(1))/60, PAR, ...
        'Color', [0.5 0.5 0.5], ...
        'LineWidth', 1, ...
        'HandleVisibility', 'off');

    ylabel('PAR / \muE');
    ax.YColor = [0.5 0.5 0.5];

    yyaxis left
end
SDs = [.5 1 2 3 4 5 6 7 8 9 10];
sdcolors = zeros(numel(SDs));

for il = 1:numel(SDs)
    for ir = 1:numel(SDs)
        sdcolors(il, ir) = SDs(ir)-SDs(il);
    end
end

imagesc(sdcolors);
sdcol = zeros([size(sdcolors) 3]);

for il = 1:numel(SDs)
    for ir = 1:numel(SDs)
        if sdcolors(il,ir) < 0
            sdcol(il, ir,:) = [0 0 0.1*abs(sdcolors(il,ir))];
        elseif sdcolors(il, ir) > 0
            sdcol(il,ir,:) = [0.1*abs(sdcolors(il,ir)) 0 0];
        else sdcol(il,ir,:) = [0 0 0];
        end
    end
end

imagesc(sdcol)
axis equal, axis xy, box off

a = gca;
a.XTick = [1 2 3 4 5 6 7 8 9 10 11]
a.XTickLabels = {0.5, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
a.YTickLabels = {0.5, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

ylabel('Left Dot Speed')
xlabel('Right Dot Speed')
xlim([.5 11.5])
ylim([.5 11.5])

hold on,
rectangle('Position',[.5, 10.5, 1, 1], 'EdgeColor', 'y', 'LineWidth', 2)
rectangle('Position',[1.5, 9.5, 1, 1], 'EdgeColor', 'y', 'LineWidth', 2)
rectangle('Position',[2.5, 8.5, 1, 1], 'EdgeColor', 'y', 'LineWidth', 2)
rectangle('Position',[3.5, 7.5, 1, 1], 'EdgeColor', 'y', 'LineWidth', 2)

rectangle('Position',[10.5, .5, 1, 1], 'EdgeColor', 'y', 'LineWidth', 2)
rectangle('Position',[9.5, 1.5, 1, 1], 'EdgeColor', 'y', 'LineWidth', 2)
rectangle('Position',[8.5, 2.5, 1, 1], 'EdgeColor', 'y', 'LineWidth', 2)
rectangle('Position',[7.5, 3.5, 1, 1], 'EdgeColor', 'y', 'LineWidth', 2)



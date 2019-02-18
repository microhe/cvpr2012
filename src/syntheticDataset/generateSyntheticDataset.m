%{
% Filename: generateSyntheticDataset.m
% Project: syntheticDataset
% Created Date: Tuesday February 12th 2019
% Author: Feng Panhe
% -----
% Last Modified:
% Modified By:
% -----
% Copyright (c) 2019 Feng Panhe
%}
function res = generateSyntheticDataset(image_num, dest_dir_path)
    %% generateSyntheticDataset - Description
    %
    % Syntax: res = generateSyntheticDataset(input)
    %
    % Long descriptions

    if ~exist('dest_dir_path', 'var') || isempty(dest_dir_path)
        dest_dir_path = fullfile('resources', 'SyntheticDataset');
    end

    if ~exist('image_num', 'var') || isempty(image_num)
        image_num = 1000;
    end

    gt_dir_path = fullfile(dest_dir_path, 'gtsave');
    im_dir_path = fullfile(dest_dir_path, 'images');

    max_shape_num = 10;

    image_size = [1200, 800];
    wseg_matix_indices = (1:(image_size(1) * image_size(2)))';
    [wseg_matix_pos_x, wseg_matix_pos_y] = ind2sub(image_size, wseg_matix_indices);
    

    % set(0, 'DefaultFigureVisible', 'off');

    for i = 1:image_num
        %% 生成 imgae_num 个 image 和 对应的 gt.mat

        im_name = sprintf('sd%d', i);
        im_file = fullfile(im_dir_path, strcat(im_name, '.jpg'));
        gt_file = fullfile(gt_dir_path, strcat(im_name, '_gt.mat'));

        edges_position = {};
        junctions_position = [0, 0];
        wseg_matix = zeros(image_size);

        % 设置画布大小。plot 标定画布的角点，可避免坐标系自动调整
        figure('Color', 'w', 'Position', [0, 0, image_size]);
        set(gca, 'position', [0 0 1 1]);
        set(gca,'YDir','reverse');
        hold on;
        plot([0, 0, image_size(1), image_size(1)], [0, image_size(2), 0, image_size(2)], '.');

        shape_num = randi(max_shape_num);

        for j = 1:shape_num
            %% 画出 shape_num 个随机图形

            % 随机画出一个图形，得到返回的顶点坐标 x，y
            shape_x = [];
            shape_y = [];
            shape_type_id = randi(2);

            switch shape_type_id
                case 1
                    [shape_x, shape_y] = drawOneRandomTriangle([0, image_size(1)], [0, image_size(2)], rand(1, 3));
                case 2
                    [shape_x, shape_y] = drawOneRandomRectangle([0, image_size(1)], [0, image_size(2)], rand(1, 3));
            end

            [wseg_matix_pos_in, ~] = inpolygon(wseg_matix_pos_x, wseg_matix_pos_y, shape_x, shape_y);
            wseg_matix(wseg_matix_pos_in) = j;

            edges_num = numel(edges_position);
            edges_position_remove_indexs = [];
            shape_junctions_x = [];
            shape_junctions_y = [];
            shape_junctions_ii = [];

            for edge_i = 1:edges_num
                % edges_position 中的每条边与 shape 进行判断
                edge_x = edges_position{edge_i}(:, 1);
                edge_y = edges_position{edge_i}(:, 2);
                [junctions_x, junctions_y, ii] = polyxpoly(shape_x, shape_y, edge_x, edge_y);

                if numel(junctions_x) > 0
                    % 新的图形与边 edge 有交点，edge将被分割并产生节点, shape 的边也被节点分割
                    new_edge_position = edgeSegmentedByShape(edge_x, edge_y, shape_x, shape_y);

                    edges_position{edge_i} = new_edge_position{1};
                    edges_position = [edges_position, new_edge_position{2:end}];

                    shape_junctions_x = [shape_junctions_x; junctions_x];
                    shape_junctions_y = [shape_junctions_y; junctions_y];
                    shape_junctions_ii = [shape_junctions_ii; ii(:, 1)];
                else
                    [edge_points_in, ~] = inpolygon(edge_x, edge_y, shape_x, shape_y);

                    if edge_points_in
                        % edge 的所有点都在 shape 内部，记录被覆盖的边
                        edges_position_remove_indexs(end + 1) = edge_i;
                    end

                end

            end

            edges_position(edges_position_remove_indexs) = [];

            % shape 的边加入
            if numel(shape_junctions_x) > 0
                new_edge_position = shapeEdgeSegmentedByPoints(shape_x, shape_y, shape_junctions_x, shape_junctions_y, shape_junctions_ii);
                edges_position = [edges_position, new_edge_position];
            else
                edges_position{end + 1} = [shape_x, shape_y];
            end

            % 删除被覆盖的 junction
            if numel(junctions_position) ~= 0
                [junction_in, ~] = inpolygon(junctions_position(:, 1), junctions_position(:, 2), shape_x, shape_y);
                junctions_position(junction_in, :) = [];
            end

            % 加入新的 junction
            junctions_position = [junctions_position; [shape_junctions_x, shape_junctions_y]];
        end % 画出图形的处理 end

        bndinfo.edges.indices = posCell2indCell(image_size, edges_position);
        bndinfo.imname = strcat(im_name, '.png');
        bndinfo.imsize = image_size([2,1]);
        bndinfo.junctions.position = round([junctions_position( :, 1), junctions_position(:,2)]);
        bndinfo.wseg = transpose(wseg_matix);
        save(gt_file, 'bndinfo');

        for ii = 1:numel(edges_position)
            hold on;
            plot(edges_position{ii}(:, 1), edges_position{ii}(:, 2), 'b', 'LineWidth', 2);
        end
        hold on;
        mapshow(junctions_position(:, 1), junctions_position(:, 2), 'DisplayType', 'point', 'Marker', 'o');

        % axis off;
        print('-dpng', '-r0', [im_file(1:end - 4) '.png']);
        % close all;
    end

    set(0, 'DefaultFigureVisible', 'on');

end

function ind_cell = posCell2indCell(xy_szie, pos_cell)
    %posCell2indCell - Description
    %
    % Syntax: ind_cell = posCell2indCell(xy_szie, pos_cell)
    %
    % Long description
    yx_size = xy_szie([2, 1]);
    ind_cell = cell(size(pos_cell));
    for i = 1:numel(pos_cell)
        pos_x = round(pos_cell{i}(:, 1));
        pos_y = round(pos_cell{i}(:, 2));
        ind_cell{i} = sub2ind(yx_size, pos_y, pos_x);
    end
end

function [output_points_x, output_points_y] = sortPoints(points_x, points_y, vx, vy)
    %sortPoints - 对坐标点组 points_x, points_y 进行排序。计算到点 [vx, vy] 的距离，从小到大进行排序。
    %
    % Syntax: [output_points_x, output_points_y] = sortPoints(points_x, points_y, vx, vy)
    %
    % Long description
    if numel(points_x) <= 1
        output_points_x = points_x;
        output_points_y = points_y;
    else
        dists = (points_x - vx).^2 + (points_y - vy).^2;
        tmp = [points_x, points_y, dists];
        tmp = sortrows(tmp, 3);
        output_points_x = tmp(:, 1);
        output_points_y = tmp(:, 2);
    end

end

function new_edge_position = edgeSegmentedByShape(edge_x, edge_y, shape_x, shape_y)
    %edgeSegmentedByShape - Description
    %
    % Syntax: new_edge_position = edgeSegmentedByShape(edge_x, edge_y, shape_x, shape_y)
    %
    % Long description

    new_edge_position = {};
    [junctions_x, junctions_y, ii] = polyxpoly(shape_x, shape_y, edge_x, edge_y);

    % 对 edge 的分割
    edge_x2 = zeros(numel(edge_x) + numel(junctions_x), 1);
    edge_y2 = zeros(numel(edge_y) + numel(junctions_y), 1);
    edge_i2 = 1;
    edge2_points_on = zeros(numel(edge_x2), 1, 'logical');
    edge2_points_on = ~edge2_points_on;

    for edge_pos_i = 1:numel(edge_x) - 1

        line_junctions_xy_indexs = find(ii(:, 2) == edge_pos_i); % 找出在 edge 上　edge_pos_i 与　edge_pos_i+１　两点之间的交点

        line_junctions_x = junctions_x(line_junctions_xy_indexs);
        line_junctions_y = junctions_y(line_junctions_xy_indexs);
        [line_junctions_x, line_junctions_y] = sortPoints(line_junctions_x, line_junctions_y, edge_x(edge_pos_i), edge_y(edge_pos_i));

        points_num = 1 + numel(line_junctions_x);
        edge_x2(edge_i2:edge_i2 + points_num - 1) = [edge_x(edge_pos_i); line_junctions_x];
        edge_y2(edge_i2:edge_i2 + points_num - 1) = [edge_y(edge_pos_i); line_junctions_y];
        edge2_points_on(edge_i2) = 0;
        edge_i2 = edge_i2 + points_num;
    end

    edge_x2(end) = edge_x(end);
    edge_y2(end) = edge_y(end);
    edge2_points_on(end) = 0;

    [egde2_points_in, ~] = inpolygon(edge_x2, edge_y2, shape_x, shape_y);
    egde2_points_in = egde2_points_in | edge2_points_on;
    start_index = 1;

    for epoi_i = 1:numel(egde2_points_in)

        if sum(egde2_points_in(start_index:epoi_i)) > 0

            if start_index < epoi_i
                start_index = start_index - 1;

                if start_index < 1
                    start_index = 1;
                end

                new_edge_x = edge_x2(start_index:epoi_i);
                new_edge_y = edge_y2(start_index:epoi_i);
                new_edge_position{end + 1} = [new_edge_x, new_edge_y];
            end

            start_index = epoi_i + 1;
        end

    end

    if egde2_points_in(end) == 0
        start_index = start_index - 1;

        if start_index < 1
            start_index = 1;
        end

        new_edge_x = edge_x2(start_index:epoi_i);
        new_edge_y = edge_y2(start_index:epoi_i);
        new_edge_position{end + 1} = [new_edge_x, new_edge_y];
    end

    if new_edge_position{1}(1, :) == new_edge_position{end}(end, :)
        new_edge_position{1} = [new_edge_position{end}; new_edge_position{1}(2:end, :)];
        new_edge_position(end) = [];
    end

end

function new_edge_position = shapeEdgeSegmentedByPoints(shape_x, shape_y, junctions_x, junctions_y, ii)
    %edgeSegmentedByPoints - Description
    %
    % Syntax: new_edge_position = edgeSegmentedByPoints(edge_x, edge_y, shape_x, shape_y)
    %
    % Long description
    %  对 shape 的边的分割
    new_edge_position = {};
    shape_x2 = zeros(numel(shape_x) + numel(junctions_x), 1);
    shape_y2 = zeros(numel(shape_y) + numel(junctions_y), 1);
    shape2_points_on = zeros(numel(shape_x2), 1, 'logical');
    shape2_points_on = ~shape2_points_on;
    shape_i2 = 1;

    for shape_i = 1:numel(shape_x) - 1
        line_junctions_xy_indexs = find(ii == shape_i); % 找出在 shape 上　shape_i 与　shape_i+１　两点之间的交点

        line_junctions_x = junctions_x(line_junctions_xy_indexs);
        line_junctions_y = junctions_y(line_junctions_xy_indexs);
        [line_junctions_x, line_junctions_y] = sortPoints(line_junctions_x, line_junctions_y, shape_x(shape_i), shape_y(shape_i));

        points_num = 1 + numel(line_junctions_x);
        shape_x2(shape_i2:shape_i2 + points_num - 1) = [shape_x(shape_i); line_junctions_x];
        shape_y2(shape_i2:shape_i2 + points_num - 1) = [shape_y(shape_i); line_junctions_y];
        shape2_points_on(shape_i2) = 0;
        shape_i2 = shape_i2 + points_num;
    end

    shape_x2(end) = shape_x(end);
    shape_y2(end) = shape_y(end);
    shape2_points_on(end) = 0;
    on_indexs = find(shape2_points_on == 1);

    for i = 1:numel(on_indexs) - 1
        indexs = on_indexs(i):on_indexs(i + 1);
        new_edge_position{end + 1} = [shape_x2(indexs), shape_y2(indexs)];
    end

    new_edge_x = [shape_x2(on_indexs(end):end); shape_x2(2:on_indexs(1))];
    new_edge_y = [shape_y2(on_indexs(end):end); shape_y2(2:on_indexs(1))];
    new_edge_position{end + 1} = [new_edge_x, new_edge_y];
end

function [shape_x, shape_y] = drawOneRandomTriangle(x_range, y_range, shape_color)
    %drawOneRandomTriangle - Description
    %
    % Syntax:  drawOneRandomTriangle(x_range, y_range, shape_color)
    %
    % Long description
    shape_x = zeros(4, 1);
    shape_y = zeros(4, 1);
    shape_x(1:3) = randi(x_range(2) - x_range(1), 3, 1) + x_range(1);
    shape_y(1:3) = randi(y_range(2) - y_range(1), 3, 1) + y_range(1);
    shape_x(end) = shape_x(1);
    shape_y(end) = shape_y(1);
    % patch(shape_x, shape_y, shape_color, 'FaceColor', 'none');
    hold on;
    patch(shape_x, shape_y, shape_color);
end

function [shape_x, shape_y] = drawOneRandomRectangle(x_range, y_range, shape_color)
    %drawOneRandomRectangle - Description
    %
    % Syntax:  drawOneRandomRectangle(x_range, y_range, shape_color)
    %
    % Long description
    shape_x = zeros(5, 1);
    shape_y = zeros(5, 1);

    x_edge_length = randi(x_range(2) - x_range(1));
    y_edge_length = randi(y_range(2) - y_range(1));

    shape_x(1) = randi(x_range(2) - x_range(1) - x_edge_length) + x_range(1);
    shape_y(1) = randi(y_range(2) - y_range(1) - y_edge_length) + y_range(1);

    shape_x(2) = shape_x(1);
    shape_y(2) = shape_y(1) + y_edge_length;

    shape_x(3) = shape_x(1) + x_edge_length;
    shape_y(3) = shape_y(1) + y_edge_length;

    shape_x(4) = shape_x(1) + x_edge_length;
    shape_y(4) = shape_y(1);

    shape_x(end) = shape_x(1);
    shape_y(end) = shape_y(1);

    % patch(shape_x, shape_y, shape_color, 'FaceColor', 'none');
    hold on;
    patch(shape_x, shape_y, shape_color);
end

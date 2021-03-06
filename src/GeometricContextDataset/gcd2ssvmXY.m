%{
%Filename: gcd2ssvmXY.m
%Project: ssvm
%Created Date: Thursday January 24th 2019
%Author: Feng Panhe
%-----
%Last Modified:
%Modified By:
%-----
%Copyright (c) 2019 Feng Panhe
%}

function [X, Y, infos, bndinfo2] = gcd2ssvmXY(file_name)
    %gcd2ssvmXY - 从gcd数据集生成ssvm的 X Y 形式的数组
    %
    % Syntax: [X, Y] = gcd2ssvmXY(mat_fileNameList)
    %
    % Long description
    % infos:
    %   +1: Edge id

    GcdGtPath = 'resources/GeometricContextDataset/gtsave/';
    GcdImPath = 'resources/GeometricContextDataset/images/';
    GcdPbimPath = 'resources/GeometricContextDataset/pbim/';

    mat_file = strcat(GcdGtPath, file_name, '_gt.mat');
    im_file = strcat(GcdImPath, file_name, '.jpg');
    pbim_file = strcat(GcdPbimPath, file_name, '_pbim.mat');

    if ~exist(mat_file, 'file')
        error('File \"%s\" does not exist.', mat_file);
    end

    if ~exist(im_file, 'file')
        error('File \"%s\" does not exist.', im_file);
    end

    im = imread(im_file);
    load(mat_file, 'bndinfo');

    if exist(pbim_file, 'file')
        load(pbim_file, 'pbim');
    else
        disp('pb');
        pbim = pbCGTG_nonmax(double(im) / 255);
        save(pbim_file, 'pbim');
    end

    [bndinfo2, ~] = updateBoundaryInfo2(bndinfo, bndinfo.labels);
    bndinfo2.pbim = pbim;

    combinedFeatures = getCombinedFeatures(bndinfo2, im);

    itemInfos = getSSVMClassifierFeatures(bndinfo2, combinedFeatures, 'train');

    Y = itemInfos(:, 1);
    infos = itemInfos(:, 2);
    X = itemInfos(:, 3:end);
end

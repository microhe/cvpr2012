%{
% Filename: sd2ssvmXY.m
% Project: ssvm
% Created Date: Wednesday February 20th 2019
% Author: Feng Panhe
% -----
% Last Modified:
% Modified By:
% -----
% Copyright (c) 2019 Feng Panhe
%}

function [X, Y, edgeid, bndinfo] = sd2ssvmXY(file_name)
    %gcd2ssvmXY - 从gcd数据集生成ssvm的 X Y 形式的数组
    %
    % Syntax: [X, Y] = gcd2ssvmXY(mat_fileNameList)
    %
    % Long description
    % infos:
    %   +1: Edge id

    GcdGtPath = 'resources/SyntheticDataset/gtsave/';
    GcdImPath = 'resources/SyntheticDataset/images/';
    GcdPbimPath = 'resources/SyntheticDataset/pbim/';

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

    bndinfo.pbim = pbim;

    combinedFeatures = getCombinedFeatures(bndinfo, im);

    itemInfos = getSSVMClassifierFeatures(bndinfo, combinedFeatures, 'train');

    Y = itemInfos(:, 1);
    edgeid = itemInfos(:, 2);
    X = itemInfos(:, 3:end);
    % edgeid_Y_X = [edgeid, Y, X];
    bndinfo.combinedFeatures = combinedFeatures;
end

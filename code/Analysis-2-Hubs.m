%%%%%%%%%%%%%%%%%%%%%%%%%  -----------    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Hubs identification
%%%%%%%%%%%%%%%%%%%%%%%%%  -----------    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
clc;
close all;
basePath = 'xxx\Gretna-Network\NodalEfficiency';
group1Path = fullfile(basePath, 'Group1-ASD-LL');
group2Path = fullfile(basePath, 'Group2-ASD-HL'); 
group3Path = fullfile(basePath, 'Group3-TD');
group1Files = dir(fullfile(group1Path, '*.mat'));
% There is only one .mat file in each path, so we can use it safely.
fileName = group1Files(1).name; 
dataGroup1 = load(fullfile(group1Path, fileName));
dataGroup2 = load(fullfile(group2Path, fileName));
dataGroup3 = load(fullfile(group3Path, fileName));
varNames = fieldnames(dataGroup1);
degreeDataGroup1 = dataGroup1.(varNames{2});
degreeDataGroup2 = dataGroup2.(varNames{2});
degreeDataGroup3 = dataGroup3.(varNames{2});
% 1. Calculate the mean and standard deviation across all subjects within each group for all nodes
meanGroup1 = mean(degreeDataGroup1(:));
stdGroup1 = std(degreeDataGroup1(:));
meanGroup2 = mean(degreeDataGroup2(:));
stdGroup2 = std(degreeDataGroup2(:));
meanGroup3 = mean(degreeDataGroup3(:));
stdGroup3 = std(degreeDataGroup3(:));
% 2: M + 1SD
thresholdGroup1 = meanGroup1 + stdGroup1; 
thresholdGroup2 = meanGroup2 + stdGroup2; 
thresholdGroup3 = meanGroup3 + stdGroup3;
Nodal_meanGroup1 = mean(degreeDataGroup1, 1);
Nodal_meanGroup2 = mean(degreeDataGroup2, 1);
Nodal_meanGroup3 = mean(degreeDataGroup3, 1);
hubIndices_Group1 = find(Nodal_meanGroup1 > thresholdGroup1);
hubIndices_Group2 = find(Nodal_meanGroup2 > thresholdGroup2);
hubIndices_Group3 = find(Nodal_meanGroup3 > thresholdGroup3);
% 3. Read the atlas_info.csv file to get node names and coordinates
atlasFilePath = fullfile( 'xxxx', 'aal_90.csv');
atlasData = readtable(atlasFilePath);
nodeNames = atlasData{:, 1}; % node names
coordinates = atlasData{:, 2:4}; % MNI coordinates
% hubs for Group1-ASD-LL
hubNodeNames_Group1 = nodeNames(hubIndices_Group1);
hubCoordinates_Group1 = coordinates(hubIndices_Group1, :);
% hubs for Group2-ASD-HL
hubNodeNames_Group2 = nodeNames(hubIndices_Group2);
hubCoordinates_Group2 = coordinates(hubIndices_Group2, :);
% hubs for Group3-TD
hubNodeNames_Group3 = nodeNames(hubIndices_Group3);
hubCoordinates_Group3 = coordinates(hubIndices_Group3, :);

allHubIndices = unique([hubIndices_Group1'; hubIndices_Group2'; hubIndices_Group3']);
commonHubIndices = intersect(intersect(hubIndices_Group1, hubIndices_Group2), hubIndices_Group3);
commonHubNames = nodeNames(commonHubIndices);
commonHubCoord = coordinates(commonHubIndices, :);
disp(' ');
disp('=================================');
disp('Hub Nodes Common to All Three Groups:');
disp('=================================');
if isempty(commonHubNames)
    disp('No common hub nodes found.');
else
    disp(table(commonHubNames, commonHubCoord));
end

% Calculate the unique Hub nodes for each group
uniqueHubIndices_Group1 = setdiff(hubIndices_Group1, commonHubIndices);
uniqueHubNames_Group1 = nodeNames(uniqueHubIndices_Group1);
uniqueHubCoord_Group1 = coordinates(uniqueHubIndices_Group1, :);
uniqueHubIndices_Group2 = setdiff(hubIndices_Group2, commonHubIndices);
uniqueHubNames_Group2 = nodeNames(uniqueHubIndices_Group2);
uniqueHubCoord_Group2 = coordinates(uniqueHubIndices_Group2, :);
uniqueHubIndices_Group3 = setdiff(hubIndices_Group3, commonHubIndices);
uniqueHubNames_Group3 = nodeNames(uniqueHubIndices_Group3);
uniqueHubCoord_Group3 = coordinates(uniqueHubIndices_Group3, :);

disp(' ');
disp('Group-ASD-LL Unique Hub Nodes:');
if isempty(uniqueHubNames_Group1)
    disp('No unique hub nodes found for this group.');
else
    disp(table(uniqueHubNames_Group1, uniqueHubCoord_Group1));
end

disp(' ');
disp('Group-ASD-HL Unique Hub Nodes:');
if isempty(uniqueHubNames_Group2)
    disp('No unique hub nodes found for this group.');
else
    disp(table(uniqueHubNames_Group2, uniqueHubCoord_Group2));
end

disp(' ');
disp('Group-TD Unique Hub Nodes:');
if isempty(uniqueHubNames_Group3)
    disp('No unique hub nodes found for this group.');
else
    disp(table(uniqueHubNames_Group3, uniqueHubCoord_Group3));
end

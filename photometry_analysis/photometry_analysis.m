clc
clear all;
close all;

directory = uigetdir;
files = dir(directory);

timeColIdx = 1;
signalColIdx = 2;
referenceColIdx = 3;

for file = files'
  
  filename = strcat(file.name);
  if isempty(strfind(filename, '.csv'))==true || isempty(strfind(filename, 'PROCESSED_'))==false
    continue
  end
  
  allData = csvread(filename, 2, 0); % skip header rows
  firstLine = find(allData(:,1) > 0.1, 1); % Lock-in data starts around 50 ms. 
  data = allData(firstLine:end, [timeColIdx signalColIdx referenceColIdx]); 
  
  DF_F0 = calculateDF_F0(data);
  
  correctedSignal = subtractReferenceAndSave(DF_F0, directory, filename);
  figure;
  plot(correctedSignal(:,1), correctedSignal(:,4));
end
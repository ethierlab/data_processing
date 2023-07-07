function data = subtractReferenceAndSave(df_f0, directory, filename)
  subtractedData = df_f0(:, 2) - df_f0(:, 3);
  data = horzcat(df_f0, subtractedData);
  cHeader = {'Time' 'Ca2+ Signal (DF/F0)' 'Reference (DF/F0)' 'Corrected'};
  commaHeader = [cHeader;repmat({','},1,numel(cHeader))];
  commaHeader = commaHeader(:)';
  textHeader = cell2mat(commaHeader);
  textHeader = textHeader(1:end-1);
  filename_w = strcat(directory,'\','PROCESSED_', filename);
  fid = fopen(filename_w,'w'); 
  fprintf(fid,'%s\n',textHeader);
  fclose(fid);
  dlmwrite(filename_w, data, 'delimiter', ',', '-append'); 
end
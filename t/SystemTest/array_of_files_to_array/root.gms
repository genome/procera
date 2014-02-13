TestTool::MakeArrayOfFiles
    contents_1 from @contents_1,
    contents_2 from @contents_2

TestTool::ConcatArrayOfFiles
    input_files from MakeArrayOfFiles.output_files,
    combination to @combination

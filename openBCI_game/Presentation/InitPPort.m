paraport = serial('COM4');
paraport.BaudRate = 115200;
paraport.DataBits = 8;
paraport.StopBits = 1;
fopen(paraport);
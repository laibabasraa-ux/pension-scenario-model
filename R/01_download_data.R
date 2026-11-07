# Download Damodaran (NYU Stern) historical returns data 
# Source: https://pages.stern.nyu.edu/~adamodar/New_Home_Page/datafile/histretSP.html

download.file(
  url = "https://www.stern.nyu.edu/~adamodar/pc/datasets/histretSP.xls",
  destfile = "data/raw/histretSP.xls",
  mode = "wb" # so the Excel file isn't corrupted
  
)
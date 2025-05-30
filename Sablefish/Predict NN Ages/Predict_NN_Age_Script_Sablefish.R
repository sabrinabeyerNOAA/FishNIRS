
########################################################
# Need >= R ver 3.0  
########################################################

if(interactive())
   setwd("C:/ALL_USR/JRW/SIDT/Sablefish/Predict_NN_Ages")  # Change path as needed

if(!interactive())
   options(width = 120)
   
# --- Load the NN model - 10-20 random models each with 10-fold complete 'k-fold' models. ---
NN_Model <- 'FCNN Model/Sablefish_2017_2019_Rdm_models_22_Mar_2023_14_57_26.RData'   

# --- Put new spectra scans in a separate folder and enter the name of the folder below ---
Spectra_Path <- "New_Scans" 

# --- The NN predicted ages will go in the path defined below ---
Predicted_Ages_Path <- "Predicted_Ages"
dir.create(Predicted_Ages_Path, showWarnings = FALSE)

TMA_Ages <- c(TRUE, FALSE)[2]

verbose <- c(TRUE, FALSE)[1]

# --------------------------------------------------------------------------------------------------

# Sys.setenv(GITHUB_PAT = '**********')  # You will need a 'GITHUB_PAT' from GitHub set somewhere in R (If you need help, search the Web how to get one from GitHub.)

#  --- Conda TensorFlow environment ---
Conda_TF_Eniv <- "C:/m3/envs/tf"  # Change this path as needed

if (!any(installed.packages()[, 1] %in% "R.utils")) 
     install.packages("R.utils") 

if (!any(installed.packages()[, 1] %in% "ggplot2")) 
     install.packages("ggplot2") 

if (!any(installed.packages()[, 1] %in% "plotly")) 
     install.packages("plotly")      
     
if (!any(installed.packages()[, 1] %in% "tensorflow")) 
     install.packages("tensorflow")
     
if (!any(installed.packages()[, 1] %in% "keras")) 
     install.packages("keras") 

library(R.utils)     
library(ggplot2)
library(plotly)        
library(tensorflow)
library(keras)  


Sys.setenv(RETICULATE_PYTHON = Conda_TF_Eniv) 
Sys.getenv("RETICULATE_PYTHON") 

# --- TensorFlow Load and Math Check  ---
a <- tf$Variable(5.56)
cat("\n\nTensorFlow Math Check\n\na = "); print(a)
b <- tf$Variable(2.7)
cat("\nb = "); print(b)
cat("\na + b = "); print(a + b)
cat("\n\n")

# --- Pause here when submitting code to R ---

k_clear_session() 


# --- Download functions from GitHub ---
sourceFunctionURL <- function (URL,  type = c("function", "script")[1]) {
          " # For more functionality, see gitAFile() in the rgit package ( https://github.com/John-R-Wallace-NOAA/rgit ) which includes gitPush() and git() "
          if (!any(installed.packages()[, 1] %in% "httr"))  install.packages("httr") 
          File.ASCII <- tempfile()
          if(type == "function")
            on.exit(file.remove(File.ASCII))
          getTMP <- httr::GET(gsub(' ', '%20', URL))
          
          if(type == "function") {
            write(paste(readLines(textConnection(httr::content(getTMP))), collapse = "\n"), File.ASCII)
            source(File.ASCII)
          } 
          if(type == "script") {
            fileName <- strsplit(URL, "/")[[1]]
            fileName <- rev(fileName)[1]
            write(paste(readLines(textConnection(httr::content(getTMP))), collapse = "\n"), fileName)
          }  
   }


sourceFunctionURL("https://raw.githubusercontent.com/John-R-Wallace-NOAA/JRWToolBox/master/R/Date.R") 
sourceFunctionURL("https://raw.githubusercontent.com/John-R-Wallace-NOAA/JRWToolBox/master/R/sort.f.R")
sourceFunctionURL("https://raw.githubusercontent.com/John-R-Wallace-NOAA/JRWToolBox/master/R/get.subs.R") 
sourceFunctionURL("https://raw.githubusercontent.com/John-R-Wallace-NOAA/JRWToolBox/master/R/extractRData.R")  
sourceFunctionURL("https://raw.githubusercontent.com/John-R-Wallace-NOAA/JRWToolBox/master/R/saveHtmlFolder.R")

sourceFunctionURL("https://raw.githubusercontent.com/John-R-Wallace-NOAA/FishNIRS/master/R/Predict_NN_Age.R")


#  ---- Note if you get this error: < Error in `[.data.frame`(data.frame(prospectr::savitzkyGolay(newScans.RAW, : undefined columns selected > or you know that 
#         the new spectra scan(s) do not have the same freq. as the model expects, then add the file 'FCNN\PACIFIC_HAKE_AAA_Correct_Scan_Freq' to your scans and an interpolation will be done. ---


# --- Use Predict_NN_Age() to find the NN predicted ages ---
fileNames <- dir(path = Spectra_Path)
Year <- apply(matrix(fileNames, ncol = 1), 1, function(x) substr(get.subs(x, sep = "_")[2], 6, 9))
# New_Ages <- Predict_NN_Age(Conda_TF_Eniv, Spectra_Path, NN_Model, plot = TRUE, NumRdmModels = 1, htmlPlotFolder = paste0(Predicted_Ages_Path, '/Spectra Figure for New Ages'), shortNameSegments = c(1,3), shortNameSuffix = Year, N_Samp = 200) # One random model for faster testing
New_Ages <- Predict_NN_Age(Conda_TF_Eniv, Spectra_Path, NN_Model, plot = TRUE, htmlPlotFolder = paste0(Predicted_Ages_Path, '/Spectra Figure for New Ages'), shortNameSegments = c(1,3), shortNameSuffix = Year, N_Samp = 200, verbose = verbose) # Use the max number of random model replicates available
# New_Ages <- Predict_NN_Age(Conda_TF_Eniv, Spectra_Path, NN_Model, plot = TRUE, htmlPlotFolder = paste0(Predicted_Ages_Path, '/Spectra Figure for New Ages'), shortNameSegments = c(1,3), shortNameSuffix = Year, N_Samp = 'All') # Plot all scans using: N_Samp = 'All'


# --- Save() ages and write out to a CSV file ---
save(New_Ages, file = paste0(Predicted_Ages_Path, '/NN Predicted Ages, ', Date(" "), '.RData'))
write.csv(New_Ages, file = paste0(Predicted_Ages_Path, '/NN Predicted Ages, ', Date(" "), '.csv'), row.names = FALSE)


# --- Create plots with age estimates and quantile credible intervals ---
New_Ages <- data.frame(Index = 1:nrow(New_Ages), New_Ages)  # Add 'Index' as the first column in the data frame
print(New_Ages[1:5, ])

Delta <- extractRData('roundingDelta', file = NN_Model)  # e.g. the rounding Delta for 2019 Hake is zero.  
New_Ages$Age_Rounded <- round(New_Ages$NN_Pred_Median + Delta)
New_Ages$Rounded_Age <- factor(" ")

cat(paste0("\n\nUsing a rounding Delta of ", Delta, "\n\n"))

# - Plot by order implied by the spectra file names -
g <- ggplotly(ggplot(New_Ages, aes(Index, NN_Pred_Median)) +  
geom_point() +
geom_errorbar(aes(ymin = Lower_Quantile_0.025, ymax = Upper_Quantile_0.975)) + 
geom_point(aes(Index, Age_Rounded, color = Rounded_Age)) + scale_color_manual(values = c(" " = "green")), dynamicTicks = TRUE)
print(g)
saveHtmlFolder(paste0(Predicted_Ages_Path, '/Predicted_Ages_Order_by_File_Names'), view = !interactive())
Sys.sleep(3)

     
# - Plot by sorted NN predicted ages -
New_Ages_Sorted <- sort.f(New_Ages, 'NN_Pred_Median') # Sort 'New_ages' by 'NN_Pred_Median', except for "Index" (see the next line below)
New_Ages_Sorted$Index <- sort(New_Ages_Sorted$Index)  # Reset Index for graphing

print(New_Ages_Sorted[1:5, ])

g <- ggplotly(ggplot(New_Ages_Sorted, aes(Index, NN_Pred_Median)) +  
geom_point() +
geom_errorbar(aes(ymin = Lower_Quantile_0.025, ymax = Upper_Quantile_0.975)) + 
geom_point(aes(Index, Age_Rounded, color = Rounded_Age)) + scale_color_manual(values = c(" " = "green")), dynamicTicks = TRUE)

print(g)
saveHtmlFolder(paste0(Predicted_Ages_Path, '/Predicted_Ages_Sorted'), view = !interactive())



# --- Check against TMA ages, if available ---

if(TMA_Ages) {

   sourceFunctionURL("https://raw.githubusercontent.com/John-R-Wallace-NOAA/JRWToolBox/master/R/load.R") 
   sourceFunctionURL("https://raw.githubusercontent.com/John-R-Wallace-NOAA/JRWToolBox/master/R/match.f.R") 
   sourceFunctionURL("https://raw.githubusercontent.com/John-R-Wallace-NOAA/FishNIRS/master/R/agreementFigure.R")

   # load("C:/ALL_USR/JRW/SIDT/Sablefish/Predict NN Ages/Predicted_Ages/NN Predicted Ages, 12 Oct 2023.RData", str = verbose)  # If re-loading - change the date in the file name as needed
   # if(verbose & !interactive())  Sys.sleep(3)
        
   # NN_Model <- 'FCNN Model/Sablefish_2017_2019_Rdm_models_22_Mar_2023_14_57_26.RData'   
   # Delta <- extractRData('roundingDelta', file = NN_Model) 
   # Predicted_Ages_Path <- "Predicted_Ages"
   
   
   load("C:/ALL_USR/JRW/SIDT/Sablefish/Keras_CNN_Models/Sable_2017_2019 21 Nov 2022.RData", str = verbose)
   if(verbose & !interactive())  Sys.sleep(3)
  
   New_Ages$Age_Rounded <- round(New_Ages$NN_Pred_Median + Delta)
   New_Ages$Rounded_Age <- factor(" ")
   New_Ages$TMA <- NULL # Clear old TMA before updating
   New_Ages <- match.f(New_Ages, Sable_2017_2019, 'filenames', 'filenames', 'TMA')   # Change as needed
   
   g <- ggplotly(ggplot(New_Ages, aes(TMA, NN_Pred_Median)) +  
   geom_point() +
   geom_errorbar(aes(ymin = Lower_Quantile_0.025, ymax = Upper_Quantile_0.975)) + 
   geom_point(aes(TMA, Age_Rounded, color = Rounded_Age)) + scale_color_manual(values = c(" " = "green")), dynamicTicks = TRUE)
   print(g)
   saveHtmlFolder(paste0(Predicted_Ages_Path, '/TMA vs Predicted_Ages'), view = !interactive())
     
   #  pdf(width = 16, height = 10, file = paste0(Predicted_Ages_Path, '/Agreement_Figure.png'))
   png(width = 16, height = 10, units = 'in', res = 600, file = paste0(Predicted_Ages_Path, '/Agreement_Figure.png'))
   
   agreementFigure(New_Ages$TMA, New_Ages$NN_Pred_Median, Delta = Delta, full = TRUE)
   
   dev.off()
   browseURL(paste0(getwd(), "/", Predicted_Ages_Path, '/Agreement_Figure.png'), browser = "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe")
}   

#   # --- Find bad scans ---
#   for ( i in fileNames)  {
#      print(i)
#      try(newScans.RAW <- opusreader::opus_read(paste(Spectra_Path, i , sep = "/"), simplify = TRUE, wns_digits = 0)[[2]] )
#   }
#   
#   
#   # Bad scans for Sablefish 2017: 505, 506, 507, 509, 511-514, 516-518, 520-522, 525, 527, 529-533, 535-538
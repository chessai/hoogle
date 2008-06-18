
module CmdLine.Search(actionSearch) where

import CmdLine.Flag
import Control.Monad
import General.Code
import Hoogle.Query.All
import System.Directory
import System.FilePath


actionSearch :: [CmdFlag] -> Query -> IO ()
actionSearch flags q = do
    db <- getDataBases flags q
    print db
    error "todo"


---------------------------------------------------------------------
-- Pick the DataBase's

-- pick "default" if there are not ones specified
-- otherwise use the CmdFlag and any +package query flags
-- 

getDataBases :: [CmdFlag] -> Query -> IO [FilePath]
getDataBases flags q = do
        (files,dirs) <- dataFileDir flags
        let pkg1 = [x | PlusPackage x <- scope q]
            pkg2 = if null pkg1 && null files then ["default"] else pkg1
        files2 <- mapM (resolveName dirs) pkg2
        return $ files++files2


-- return the (files,dirs), error message if one does not exist
dataFileDir :: [CmdFlag] -> IO ([FilePath],[FilePath])
dataFileDir flags = f [x | DataPath x <- flags]
    where
        f [] = return ([],[])
        f (x:xs) = do
            ft <- fileType x
            when (ft == NotFound) $
                failMessage ["File given with the --data flag does not exist"
                            ,"    " ++ x]
            (fs,ds) <- f xs
            return $ if ft == File then (x:fs,ds) else (fs,x:ds)


-- change PlusPackage flags from names to files
resolveName :: [FilePath] -> String -> IO FilePath
resolveName dirs x = f (dirs ++ ["."])
    where
        f [] = failMessage ["DataBase not found","    " ++ x] >> return ""
        f (d:ds) = do
            let s = d </> x
            b <- doesFileExist s
            if b then return s else f ds

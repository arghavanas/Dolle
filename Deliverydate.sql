USE [GOERP]
GO

/****** Object:  Trigger [dbo].[trg_UpdateLieferterminn]    Script Date: 1/24/2025 1:07:38 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE TRIGGER [dbo].[trg_UpdateLieferterminn]
ON [dbo].[AUFTRAG]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if INKOMMISSION changed from 0 to 1 and restrict to KNDNR = 1008
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d ON i.LFDANGAUFGUTNR = d.LFDANGAUFGUTNR
        JOIN ANGAUFPOS ap ON ap.LFDANGAUFGUTNR = i.LFDANGAUFGUTNR
        JOIN ANGAUFGUT ag ON ag.LFDNR = ap.LFDANGAUFGUTNR
        WHERE d.INKOMMISSION = 0
          AND i.INKOMMISSION = 1
          AND ag.KNDNR = 1008 -- Restrict to specific customer
    )
    BEGIN
        -- Option 1: Use CASE directly inside the update
        UPDATE ap
        SET LIEFERTERMIN = [dbo].[calbusinessdate](
                               GETDATE(),
                               CASE 
                                  WHEN DATENAME(WEEKDAY, GETDATE()) IN ('Samstag','Sonntag') THEN 2
                                  ELSE 1
                               END
                           )
        FROM ANGAUFPOS ap
        INNER JOIN inserted i ON ap.LFDANGAUFGUTNR = i.LFDANGAUFGUTNR
        INNER JOIN ANGAUFGUT ag ON ag.LFDNR = ap.LFDANGAUFGUTNR
        WHERE i.INKOMMISSION = 1 
          AND ag.AAGAUFART = 9
          AND ag.KNDNR = 1008;

        UPDATE ag
        SET LIEFERTERMIN = [dbo].[calbusinessdate](
                               GETDATE(),
                               CASE 
                                  WHEN DATENAME(WEEKDAY, GETDATE()) IN ('Samstag','Sonntag') THEN 2
                                  ELSE 1
                               END
                           )
        FROM ANGAUFGUT ag
        INNER JOIN ANGAUFPOS ap ON ag.LFDNR = ap.LFDANGAUFGUTNR
        INNER JOIN inserted i ON ap.LFDANGAUFGUTNR = i.LFDANGAUFGUTNR
        WHERE i.INKOMMISSION = 1
          AND ag.AAGAUFART = 9
          AND ag.KNDNR = 1008;

        /*
          -- Option 2: Alternatively, declare a variable for clarity:
          
          DECLARE @DaysToAdd INT;

          IF DATENAME(WEEKDAY, GETDATE()) IN ('Friday','Saturday','Sunday')
              SET @DaysToAdd = 2;
          ELSE
              SET @DaysToAdd = 1;

          UPDATE ap
          SET LIEFERTERMIN = [dbo].[calbusinessdate](GETDATE(), @DaysToAdd)
          FROM ANGAUFPOS ap
               ...
          
          UPDATE ag
          SET LIEFERTERMIN = [dbo].[calbusinessdate](GETDATE(), @DaysToAdd)
          FROM ANGAUFGUT ag
               ...
        */
    END
END;
GO

ALTER TABLE [dbo].[AUFTRAG] ENABLE TRIGGER [trg_UpdateLieferterminn]
GO



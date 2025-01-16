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
        -- Update the LIEFERTERMIN in ANGAUFPOS
        UPDATE ap
        SET LIEFERTERMIN = [dbo].[calbusinessdate]( getdate(),1)
        FROM ANGAUFPOS ap
        INNER JOIN inserted i ON ap.LFDANGAUFGUTNR = i.LFDANGAUFGUTNR
        INNER JOIN ANGAUFGUT ag ON ag.LFDNR = ap.LFDANGAUFGUTNR
        WHERE i.INKOMMISSION = 1 and ag.AAGAUFART=9
          AND ag.KNDNR = 1008;

        -- Update the LIEFERTERMIN in ANGAUFGUT
        UPDATE ag
        SET LIEFERTERMIN = [dbo].[calbusinessdate]( getdate(),1)
        FROM ANGAUFGUT ag
        INNER JOIN ANGAUFPOS ap ON ag.LFDNR = ap.LFDANGAUFGUTNR
        INNER JOIN inserted i ON ap.LFDANGAUFGUTNR = i.LFDANGAUFGUTNR
        WHERE i.INKOMMISSION = 1 and ag.AAGAUFART=9
          AND ag.KNDNR = 1008;
    END
END;
GO 


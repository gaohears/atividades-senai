USE master;
GO

EXEC master.dbo.xp_create_subdir 'C:\AuditoriaSQL';
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_audits WHERE name = 'Auditoria_RPG')
    CREATE SERVER AUDIT Auditoria_RPG
    TO FILE (FILEPATH = 'C:\AuditoriaSQL\', MAXSIZE = 10 MB, MAX_ROLLOVER_FILES = 5)
    WITH (ON_FAILURE = CONTINUE);
GO
ALTER SERVER AUDIT Auditoria_RPG WITH (STATE = ON);
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = 'Spec_Servidor_RPG')
    CREATE SERVER AUDIT SPECIFICATION Spec_Servidor_RPG
    FOR SERVER AUDIT Auditoria_RPG
        ADD (FAILED_LOGIN_GROUP),
        ADD (SUCCESSFUL_LOGIN_GROUP)
    WITH (STATE = ON);
GO

USE RPG_aula;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = 'Spec_Banco_RPG')
    CREATE DATABASE AUDIT SPECIFICATION Spec_Banco_RPG
    FOR SERVER AUDIT Auditoria_RPG
        ADD (SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo BY public),
        ADD (SCHEMA_OBJECT_CHANGE_GROUP)
    WITH (STATE = ON);
GO

EXECUTE AS USER = 'usr_leitura';

    SELECT NomePersonagem FROM PERSONAGENS;

    BEGIN TRY
        INSERT INTO CLASSES (Nome, Descricao) VALUES ('Teste', 'Não deve entrar');
    END TRY
    BEGIN CATCH
        PRINT 'INSERT negado (esperado): ' + ERROR_MESSAGE();
    END CATCH;

    BEGIN TRY
        DELETE FROM PERSONAGENS;
    END TRY
    BEGIN CATCH
        PRINT 'DELETE negado (esperado): ' + ERROR_MESSAGE();
    END CATCH;

    BEGIN TRY
        SELECT Senha FROM USUARIOS;
    END TRY
    BEGIN CATCH
        PRINT 'SELECT na Senha negado (esperado): ' + ERROR_MESSAGE();
    END CATCH;

REVERT;
GO

UPDATE CLASSES SET Descricao = Descricao WHERE ClasseId = 1;
GO

SELECT event_time,
       action_id,
       succeeded,
       session_server_principal_name AS usuario,
       database_name,
       object_name,
       statement
FROM sys.fn_get_audit_file('C:\AuditoriaSQL\*.sqlaudit', DEFAULT, DEFAULT)
ORDER BY event_time DESC;
GO
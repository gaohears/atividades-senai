USE RPG_aula;
GO

INSERT INTO USUARIOS (Email, Senha) VALUES
    ('arthur@email.com',  CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'Arthur@2026'), 2)),
    ('beatriz@email.com', CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'Beatriz@2026'), 2)),
    ('carlos@email.com',  CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'Carlos@2026'), 2));

INSERT INTO CLASSES (Nome, Descricao) VALUES
    ('Guerreiro', 'Combatente corpo a corpo'),
    ('Mago',      'Usuário de magias'),
    ('Arqueiro',  'Atacante à distância');

INSERT INTO HABILIDADES (Nome) VALUES
    ('Golpe Forte'),
    ('Bola de Fogo'),
    ('Tiro Preciso'),
    ('Escudo Protetor');

INSERT INTO CLASSES_HABILIDADES (ClasseId, HabilidadeId) VALUES
    (1, 1), (1, 4), (2, 2), (3, 3);

INSERT INTO PERSONAGENS (NomePersonagem, UsuarioId, ClasseId) VALUES
    ('Arthas',  1, 1),
    ('Merlin',  1, 2),
    ('Legolas', 2, 3);
GO

SELECT p.NomePersonagem, u.Email AS Jogador, c.Nome AS Classe
FROM PERSONAGENS p
INNER JOIN USUARIOS u ON u.UsuarioId = p.UsuarioId
INNER JOIN CLASSES  c ON c.ClasseId  = p.ClasseId;

SELECT c.Nome AS Classe, h.Nome AS Habilidade
FROM CLASSES c
INNER JOIN CLASSES_HABILIDADES ch ON ch.ClasseId = c.ClasseId
INNER JOIN HABILIDADES h ON h.HabilidadeId = ch.HabilidadeId;
GO

UPDATE PERSONAGENS
SET NomePersonagem = 'Merlin, o Mago'
WHERE NomePersonagem = 'Merlin';

UPDATE CLASSES
SET Descricao = 'Combatente corpo a corpo com alta defesa'
WHERE Nome = 'Guerreiro';
GO

INSERT INTO USUARIOS (Email, Senha)
VALUES ('teste@email.com', CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'Teste@2026'), 2));

INSERT INTO PERSONAGENS (NomePersonagem, UsuarioId, ClasseId)
VALUES ('PersonagemTeste', (SELECT UsuarioId FROM USUARIOS WHERE Email = 'teste@email.com'), 1);

DELETE FROM PERSONAGENS WHERE NomePersonagem = 'PersonagemTeste';
DELETE FROM USUARIOS    WHERE Email = 'teste@email.com';
GO

CREATE PROCEDURE sp_CadastrarPersonagem
    @NomePersonagem VARCHAR(100),
    @UsuarioId INT,
    @ClasseId INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM USUARIOS WHERE UsuarioId = @UsuarioId)
        THROW 50001, 'Usuário não encontrado.', 1;

    IF NOT EXISTS (SELECT 1 FROM CLASSES WHERE ClasseId = @ClasseId)
        THROW 50002, 'Classe não encontrada.', 1;

    INSERT INTO PERSONAGENS (NomePersonagem, UsuarioId, ClasseId)
    VALUES (@NomePersonagem, @UsuarioId, @ClasseId);
END;
GO

EXEC sp_CadastrarPersonagem @NomePersonagem = 'Robin', @UsuarioId = 3, @ClasseId = 3;
GO

CREATE TABLE LOG_PERSONAGENS (
    LogId        INT IDENTITY(1,1) PRIMARY KEY,
    PersonagemId INT NOT NULL,
    NomePersonagem VARCHAR(100) NOT NULL,
    DataHora     DATETIME DEFAULT GETDATE()
);
GO

CREATE TRIGGER TRG_PERSONAGENS_Insert
ON PERSONAGENS
AFTER INSERT
AS
BEGIN
    INSERT INTO LOG_PERSONAGENS (PersonagemId, NomePersonagem)
    SELECT PersonagemId, NomePersonagem FROM inserted;
END;
GO

EXEC sp_CadastrarPersonagem @NomePersonagem = 'Gimli', @UsuarioId = 2, @ClasseId = 1;

SELECT * FROM LOG_PERSONAGENS;
GO

USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_jogador')
    CREATE LOGIN login_jogador WITH PASSWORD = 'Troque#Jogador2026!';
GO

USE RPG_aula;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_jogador')
    CREATE USER usr_jogador FOR LOGIN login_jogador;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_jogador' AND type = 'R')
    CREATE ROLE rol_jogador;
GO

ALTER ROLE rol_jogador ADD MEMBER usr_jogador;

GRANT SELECT  ON CLASSES     TO rol_jogador;
GRANT SELECT  ON HABILIDADES TO rol_jogador;
GRANT EXECUTE ON sp_CadastrarPersonagem TO rol_jogador;

DENY SELECT, INSERT, UPDATE, DELETE ON USUARIOS TO rol_jogador;
GO
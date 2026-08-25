/*

Databasemail
Database Mail (Datenbank-E-Mail) ist die
integrierte Lösung in Microsoft SQL Server,
mit der die Datenbank-Engine E-Mail-Nachrichten 
über das Standard-Protokoll SMTP (Simple Mail Transfer Protocol) 
versenden kann – ganz ohne MAPI-Client oder Outlook auf dem Server.

Technische Umsetzung
[ T-SQL / Agent Job ] 
        │
        ▼ (sp_send_dbmail)
[ msdb: Service Broker Queue ] 
        │
        ▼ (aktiviert)
[ DatabaseMail.exe (Externer Prozess) ] 
        │
        ▼ (SMTP / TLS)
[ SMTP-Mailserver / Relay / M365 ] 
        │
        ▼
[ Empfänger ]


!! Der T-SQL-Befehl (spS-end_dbmail) kehrt sofort zurück, ohne auf die E-Mail-Zustellung zu warten.


Kernkomponenten
Accounts (Konten): Speichern die SMTP-Verbindungsinformationen 
(Servername, Port, Authentifizierungsmethode, TLS/SSL, Absenderadresse).

Profiles (Profile): Fassen ein oder mehrere Accounts zusammen. 
	Ein Profil kann öffentlich (Public) 
	oder privat (Private, nur für bestimmte DB-Rollen/Benutzer) sein.

Failover-Mechanismus: Sind in einem Profil mehrere Accounts hinterlegt
	(z. B. Primär-SMTP und Backup-SMTP), versucht Database Mail 
	bei Ausfall des ersten Accounts automatisch den zweiten.

Sicherheitsrollen in msdb:

DatabaseMailUserRole: Berechtigt Benutzer/Rollen, 
	sp_send_dbmail auszuführen und Profile zu nutzen.


Dienst                 | SMTP-Endpunkt & Port                         | Besonderheiten & Hürden                                                                                                           | Empfohlene Lösung / Best Practice
-----------------------+----------------------------------------------+-----------------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------
Exchange on-premises   | Eigener Server-FQDN / IP (Port 25 oder 587)  | Unkomplizierteste Variante. E-Mail-Relay kann rein über Quell-IP-Freigabe (Whitelist) ohne Passwort gesteuert werden.             | Dedicated Receive Connector einrichten mit IP-Restriktion auf die SQL-Server-IP und anonymem/internem Relay-Recht.
Googlemail / Gmail     | smtp.gmail.com (Port 587 TLS / 465 SSL)      | Reguläres Kontopasswort funktioniert wegen 2FA nicht. Tägliche Sendelimits für Konten beachten.                                  | App-Passwort im Google-Konto generieren (erfordert aktivierte 2FA) und als Passwort in Database Mail hinterlegen.
Outlook.com / M365     | smtp-mail.outlook.com / smtp.office365.com   | Microsoft erzwingt Modern Auth (OAuth 2.0). Basic Auth & SMTP AUTH pro Postfach oft standardmäßig deaktiviert.                    | Postfach-spezifisches App-Kennwort (falls aktiviert) ODER lokales SMTP-Relay (z. B. IIS SMTP / Postfix) als Proxy für OAuth2/Direct Send vorschalten.


Theoretisch lokaler SMTP Server (Windows) 
- Zugriff und Relay auf IP des SQL Servers
- Smarthost eintragen (FQDN eintragen)

SMTP Server  in der Gegend für Versand 
kann auch ein lokaler SMTP Server sein oder auch MM365 

Was braucht man?

Profil
	SMTP Konto
			email
			Servername (SMTP Server)
			Port 25 zB
			Authentifizierung
	Sicherheit
		öfftl Profil (Mitglied einer Gruppe: DatabaseMailuserRole  msdb)   Rolle = Gruppe
		privates Profile  gezielte direkte Rechtevergabe am Profil

Unter Verwaltung legt man das Profil an und gibt entsprechend die Infos ein
Evtl kommt eine Meldung: Broker etc muss aktiviert sein.. Ja ! sonst keine Mail:-(

Systemparameter. Evtl Anhanggröße von 1 MB  10MB einstellen...

	NT SMTP Server
		c.\inetpub\mailroot\
					drop  (ankommende Mails)
					queue
					badmail
					pickup (mails zu versenden)

Assisten richtet alles ein
--> Achtung
GAST hat Recht auf Profil bekommen!!

Nach Einrichten des Profiles:

bis dato: Mails können veschickt werden.. per TSQL gehts
aber nicht der Agent ;-) kein Auftrag versendet Mails..!


Grund:

Dem Agent ein Profil zuweisen und Warnungssystem aktiveren--> Eigenschaften des Agent
Restart des Agent!!

--> GAST hat Recht auf öfftl Profil bekommen

--Wer hat die Mails versendet..? der Agent
--bei SQL 2014 oder früher hätte es ein Problem gegeben

--> databaseMailUserRole


Gast wurde in msdb aktiviert (jeder der ein Login besitzt kotmmt zur msb rein)
--Gast Mitglied in Databasemailuserrole ... schon klappts mit öfftl Profil)

--Sond


Warnungen






*/




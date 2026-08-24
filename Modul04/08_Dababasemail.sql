/*

Databasemail


SMTP Server irgendwo in der Gegend für Versand 
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




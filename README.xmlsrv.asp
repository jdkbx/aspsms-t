Query example:

<iq to='smstest.swissjabber.ch/xmlsrv.asp' type='set' id='23'>
<aspsms>
 <Userkey>USERKEY</Userkey>
 <Password>PASSWORD</Password>
 <Action>ShowCredits</Action>
</aspsms>
</iq>

Response:
<iq xml:lang="en" from="aspsms.swissjabber.ch/xmlsrv.asp" type="result" id="23" to="micressor@swissjabber.ch/mabaws02/psi" >
 <aspsms>
 <ErrorCode>1</ErrorCode>
 <ErrorDescription>Ok</ErrorDescription>
 <Credits>2321.21</Credits>
 </aspsms>
</iq>

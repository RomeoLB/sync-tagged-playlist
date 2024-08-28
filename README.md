# sync-tagged-playlist - VIDEO ONLY
Sync video playback for tagged playlist

This plugin and presentation combo will allow the user to play a specific tagged playlist in sync accross multiple Brightsign players.

1. You will need to create a Tagged playlist using a BSN.Content account

<img width="1186" alt="image" src="https://github.com/user-attachments/assets/967d9043-037e-4a2e-8fe9-22f82452eb87">

2. Make a careful note for the name of the Tagged playlist that you have created in step 1 as you will need to enter that name as as User Variable later on. In my example the Tagged playlist name is "Sync-Tagged-playlist" (as per the above print screen)
3. Download the BrightAuthor:Connected (BACon) presentation "Tag-playlist-sync-Pres.bpfx"
4. Using the Mac/Windows BACon client set to "Local", open the "Tag-playlist-sync-Pres.bpfx" presentation
   
<img width="1263" alt="image" src="https://github.com/user-attachments/assets/6cf1ba49-4dea-4120-8035-5c84f90f10a9">

6. Go to Presentation Settings > Variables > playlist_name and enter the name of the Tagged playlist that you have created on step 1
   
<img width="958" alt="image" src="https://github.com/user-attachments/assets/7f75feb6-0093-4afb-a300-40efe9ea50af">

7. Under the Variables > master_serials, enter the serial number of ONE of the players in your sync group that you would like to set as a Master/Leader player - Note that you can ONLY have 1 Master/Leader player per sync group!
   
<img width="952" alt="image" src="https://github.com/user-attachments/assets/2869c255-86e9-4b6b-86f9-4d0b226f67f7">

8. Whilst signed in to your target network but with the environement still set to Local, click on the upload icon to upload the modified presentation to your network

<img width="1171" alt="image" src="https://github.com/user-attachments/assets/da47b931-ad0d-4031-bc0d-e470085d6862">

9. Once the modified presentation has been uploaded move the slider to the BSN.cloud environment

<img width="980" alt="image" src="https://github.com/user-attachments/assets/113ff22d-43bb-4892-88f3-98be0ea928fe">
 
10. In the presentation Library (Presentation > Library), locate the recently uploaded presentation and open it

<img width="1123" alt="image" src="https://github.com/user-attachments/assets/55cb890b-c2aa-4465-91f7-ab29670615ee">

11. Select the "Feed-container" state, go to State Properties > List Content, then select "Tagged playlist", then select from the list the Tagged Playlist that you have specified in step 6 for the "playlist_name" user variable.

<img width="957" alt="image" src="https://github.com/user-attachments/assets/ac1fa381-eca0-4e38-9a0e-fadb8033254b">

12. Save the presentation and pubish it to a BSN.Content player group

Note: 
 - Both Master and Slave(s) players should be assigned to that same group for synchronised video playback.
 - Multiple Masters/Leaders players from different sites/locations can be specified via the "master_serials" user Variable in the following format "D7E8A0001986:D7E8A0001985:D7E8A0001984" where each player serial number (1 for each master/leader) is separated by the ":" charater.





   


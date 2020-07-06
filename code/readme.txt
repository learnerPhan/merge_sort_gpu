--------------------TEST---------------------------------------
Nous proposons un test sur 2 tableaux de taille 128.
Pour faire le test:
./mmake.sh JeuxDeDonnees/EXP/ex_N256_alea.

Pour faire des autres tests, certains changements sont nécessaires.
Veuillez lire la suite pour plus d'information.


--------------------USAGE--------------------------------------
Pour faire des tests sur gpu, il faut d'abord générer un fichier qui contient des données de tableaux A et B.
Pour cela:
cd JeuxDeDonnees/EXP/
./Alea.sh [taille de A] [taille de B] [valeur maximum des elements de A,B]

Cet étape va produire le fichier ex_Nx_alea où x est taille_de_A + taille_de_B

Pour éxécuter le code :
cd ../..
./mmake.sh JeuxDeDonnees/EXP/ex_Nx_alea

Si l'affichage est comme suivant :
Make sure : SIZE = x, NTPB = y
Please retry

aller dans fichier MergeGPU.cu, changer 2 macros NTPB et SIZE à lignes 7 et 9 et refaire
./mmake.sh JeuxDeDonnees/EXP/ex_Nx_alea.


--------------------EXEMPLE--------------------------------------
Si on veut faire une test sur des tableaux de taille 8 des éléments plus petits que 20 :
cd JeuxDeDonnees/EXP
./Alea.sh 8 8 20
cd ../..
./mmake.sh JeuxDeDonnees/EXP/ex_N16_alea

Si on veut faire une autre test sur des tableaux de taille 128 :
cd JeuxDeDonnees/EXP
./Alea.sh 128 128 400 
cd ../..
./mmake.sh JeuxDeDonnees/EXP/ex_N256_alea

Il dit :
Make sure : SIZE = 128, NTPB = 64
Please retry

Ouvrir MergeGPU.cu, changer à lignes 7 et 9
#define NTPB 64
#define SIZE 128

refaire:
./mmake.sh JeuxDeDonnees/EXP/ex_N256_alea



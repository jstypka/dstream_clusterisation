dstream_clusterisation
======================

Aplikacja pozwala na klasteryzację danych zgodnie z algorytmem Dstream w wersji offline. Dane wejściowe (dowolnego wymiaru) dostarczane są w pliku wejściowym, który zostaje wczytany i wstępnie przetworzony przez moduł `offline_dstream`, a następnie sklasteryzowane przez drugi moduł `clusterisation`. W pliku wyjściowym wygenerowanym przez ostatni moduł znajdują się poszczególne rekordy podzielone na klastry.

Algorytm jest zaimplementowany w paradygmacie MapReduce i wykonuje się przy wykorzystaniu narzędzia [Apache Hadoop](http://hadoop.apache.org/), które jest konieczne do jego uruchomienia. W celu zwiększenia wydajności zaleca się uruchamianie go na rozproszonej architekturze, która umożliwia przetwarzanie równoległe.

## Zależności

Wymagane oprogramowanie:
* [Java](http://www.java.com/pl/)
* [Maven](http://maven.apache.org/)

Pozostałe dependencje zawarte są w plikach `pom.xml` i powinne zostać pobrane automatycznie podczas budowania projektu

## Budowanie projektu

Aby zbudować i uruchomić program należy wykonać:

    ~$ git clone https://github.com/jstypka/dstream_clusterisation.git
    ~$ cd dsteam_clusterisation/
    ~$ git submodule foreach pull origin master
    ~$ ./compile.sh
    
Projekt zostanie ściągnięty i zbudowany przez narzędzie Maven, a wszystkie dependencje powinne zostać ściągnięte z internetu.
W razie problemów ze skryptem `compile.sh` można również wywołać polecenie `mvn install` w folderach `clusterisation` oraz `mapreduce`, co powinno mieć podobny efekt.

## Uruchamianie projektu

Aby uruchomić proces klasteryzacji, należy umieścić dane wejściowe w odpowiednim formacie w folderze `input` i wykonać polecenie:

    ~$ ./run.sh

Dane wyjściowe powinne znaleźć się w folderze `output`. Oba foldery powinne być stworzone przed uruchomieniem aplikacji, inaczej pojawi się błąd.

## Opis algorytmu

Algorytm zaimplementowany w programie opiera się na pomyśle prof. Yixin Chen oraz prof. Li Tu, którzy przedstawili ten algorytm w artykule pt. _Density-Based Clustering for Real-Time Stream Data_. Całość artykułu można znaleźć pod adresem: [http://www.cse.wustl.edu/~ychen/public/sigproc-sp.pdf](http://www.cse.wustl.edu/~ychen/public/sigproc-sp.pdf).



## Implementacja

Sam program podzielony jest na dwie niezależne części: `mapreduce` oraz `clusterisation`, które są wykonywane sekwencyjnie. Część pierwsza odpowiada za wczytanie danych wejściowych, ich znormalizowanie i wreszcie scalenie - tworząc listę, której elementami jest para (Coordinates, Density) = (Współrzędne gridu, Gęstość gridu). Zapisuje ona wyniki w folderze `pipe`, z którego pobiera dane drugi moduł. Dokładna implementacja i opis tej części algorytmu znajduje się w sekcji `MapReduce`.

Drugą częścią aplikacji jest moduł `clusterisation`, który operuje na danych wyjściowych części poprzedniej. Odpowiada on za przetworzenie całej znanej części przestrzeni rozwiązań i stworzenie listy klastrów, które odpowiadają grupom gridów o największej gęstości. Dane te są zapisywane do folderu `output`. Dokładny opis tej części algorytmu znajduje się w sekcji `Clusterisation`.

## MapReduce

## Clusterisation

Moduł clusterisation odpowiada za podzielenie danych przetworzonych przez `mapreduce` na klastry. W jego działaniu (poza wczytaniem i wypisywanie danych) wyróżniamy trzy etapy:

* createClusters()
* attachTransitionalGrids()
* mergeClusters()

 
### createClusters()

Po wczytaniu danych wejściowych każdemu dense gridowi został przyporządkowany osobny klaster. Funkcja `createClusters()` ma na celu stworzenie z sąsiadujących ze sobą gridów większe grupy i przyporządkowanie im tych samych klastrów. Do wykonania tego zadania wykorzystywany jest algorytm przeszukiwania grafu DFS, który operuje tylko na dense gridach ignorując zupełnie transitional gridy. Przy okazji tego przeglądania całej gridlisty tworzona jest lista wszystkich transitional gridów sąsiadujących z dense gridami.

### attachTransitionalGrids()

Obecna funkcja iteruje właśnie po tej świeżo stworzonej liście próbując "dokleić" transitional gridy do sąsiadujących z nimi klastrów. Podczas tej operacji w razie konfliktu grid jest doczepiany do największego klastra i cały czas pilnowany jest warunek, żeby żaden transitional grid nie był otoczony dense gridami z tego samego klastra (sprzeczne z definicją klastra). Operacja ta zostaje przerwana, gdy nie można dokonać już żadnej zmiany.

### mergeClusters()

Ostatnią operacją jest scalanie postałych klastrów. Jako, że wszystkie dense gridy są już w jednym klastrze co inne sąsiadujące gridy o tym stopniu gęstości, więc funkcja przegląda tylko transitional gridy. Zachowując dwie zasady opisane wyżej (przy konflikcie grid doczepiany jest do większego z klastrów oraz żaden transitional grid nie może być otoczony przez dense gridy należące do tego samego klastra), dla każdego przeglądanego grida próbujemy scalić sąsiadujące z nim klastry. Funkcja kończy się, gdy nie da się dokonać już żadnej operacji.

Po ostatnim z powyższych kroków, gridlista jest sklasteryzowana i może zostać zwrócona jako wynik algorytmu. Dane zostają zapisane do pliku o ścieżce `output/clusters`.







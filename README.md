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
    ~$ git submodule update --init --recursive
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

Główną składową aplikacji jest zadanie (job) MapReduce frameworku Apache Hadoop, którego dane wynikowe są używane przez moduł klasteryzacji. Przeznaczone jest ono do wykonywania na instancji Hadoopa w wersji 2.0, wykorzystując tzw. "nowe API" MapReduce.

Zadanie składa się z czterech głównych elementów. Są to: mapper, comparator (group comparator), partitioner oraz reducer. Ich implementacja została opisana poniżej.

### Dane wejściowe

Dane wejściowe dla zadania MapReduce powinien stanowić plik, który w każdej linii zawiera znacznik czasowy (timestamp) wyrażony liczbą całkowitą, a następnie `k` całkowitoliczbowych wartości reprezentujących współrzędne pojedynczego rekordu w `k`-wymiarowej przestrzeni. Wszystkie wspomniane wartości są rozdzielane znakiem spacji.

Rekord to jednostkowy pomiar zarejestrowany w czasie określonym przez timestamp, który przynależąc do danego gridu wnosi wkład w obliczaną w zadaniu gęstość tego gridu.

Tym samym, fragment danych wejściowych (tutaj dla dwuwymiarowej przestrzeni) mógłby wyglądać następująco:

    1 150 140
    2 450 460
    3 510 350

Przykładowo, w drugiej linii zapisany został pojedynczy rekord o znaczniku czasowym równym `2` oraz współrzędnych `(450, 460)`.

Oprócz powyższego pliku, danymi wejściowymi są także, podawane w linii argumentów, liczba rekordów w pliku wejściowym oraz wymiar gridu (pojedyncza wartość stosowana dla wszystkich wymiarów). Właściwy dobór tego ostatniego ma kluczowy wpływ na proces klasteryzacji.

### Mapper

Mapper, zaimplementowany w klasie `OffDstreamMapper`, jest odpowiedzialny za przetworzenie pojedynczej linii pliku wejściowego zawierającej znacznik czasowy oraz współrzędne rekordu na parę `(klucz, wartość)`, gdzie klucz stanowi krotka `(współrzędne gridu, timestamp)` a wartość jest równa `timestamp`. Występująca tu redundantność danych (znacznik czasowy) wynika z konieczności zapewnienia warunku dostarczenia do reducera danych posortowanych zględem timestampu. Szczegóły zostały przedstawione w opisie reducera.

Współrzędne gridu wchodzące w skład danych wyjściowych mappera są wyliczane w oparciu o wymiarowość przestrzeni rekordów (wnioskowaną na bazie wartości w przetwarzanej linii pliku wejściowego) oraz wymiary gridu podawane jako argument wywołania zadania. Z punktu widzenia dalszego przetwarzania stanowią one główne dane, zastępując szczegółowe współrzędne pojedynczego rekordu.

### Comparators

Zadanie `OffDstream` wykorzystuje dwa comparatory: `KeyComparator` oraz `GroupComparator`. Pierwszy z nich odpowiada za porównywanie krotek przekazywanych przez mappera w celu dostarczenia do reducera danych posortowanych względem współrzędnych gridu oraz, co jest tu kluczowe, względem znacznika czasowego w tej krotce. Dzięki temu dane wejściowe reducera są ułożone zgodnie z rosnącą wartością timestamp, co pozwala mu sekwencyjnie przetwarzać te dane, bez dodatkowego (i czasochłonnego) ich sortowania.

Drugi z comparatorów, `GroupComparator`, odpowiada za grupowanie danych wyjściowych mappera, które są następnie przekazywane do reducera. Dane są grupowane względem współrzędnych gridu zawartych w przetwarzanej krotce.

Oba opisane tu comparatory składają się na relizację mechanizmu *secondary sort*, który pozwala zachować ustaloną kolejność danych wejściowych reducerów, która domyślnie jest dowolna i może różnić się pomiędzy kolejnymi uruchomieniami zadania.

### Partitioner

Partitioner, zaimplementowany w klasie `OffDstreamPartitioner`, realizuje zadanie polegające na wyznaczeniu konkretnego reducera, do którego mają trafić dane przetworzone przez mapper oraz comparatory (w naszym wypadku krotka oraz znacznik czasowy). Procedura ta opiera się na obliczaniu funkcji haszującej.

### Reducer

Reducer (`OffDstreamReducer`) stanowi ostatni etap przetwarzania danych w obrębie zadania. W każdym wywołaniu metody `reduce` otrzymuje on krotkę `(współrzędne gridu, timestamp)` oraz kolekcję posortowanych znaczników czasowych - wszystkich, dla których został zarejestrowany rekord przyporządkowany do gridu o współrzędnych z krotki. Następnie w oparciu o wartości timestampów wyznaczana jest gęstość dla danego gridu według schematu przedstawionego w referencyjnej realizacji algorytmu D-Stream. Gęstość ta, zanim zostanie przekazana na wyjście zadania, jest jednokrotnie odświeżana dla znacznika czasowego równego liczbie rekordów w pliku wejściowym, który podawany jest jako argument uruchamianego zadania MapReduce.

### Dane wyjściowe

Na dane wyjściowe składają się tym samym wyniki, dla których pojedyncza linia określa współrzędne danego gridu oraz wyznaczoną dla niego gęstość. Obie te wartości są rozdzielone pojedynczym znakiem tabulacji. Przykładowe dane wyjściowe zostały przedstawione poniżej:

    (0,0)   1.40960
    (1,1)   2.15200
    (1,2)   1.80000
    (2,1)   1.00000

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







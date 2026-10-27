# GearTags — 0.1.0-alpha

WoW Classic Era için elle eşya etiketleme, çantada filtreleme/vurgulama ve ek satış kontrolü.

Hedef istemci: **Classic Era 1.15.9**, Interface **11509**. Kontrol edilen Classic Era UI kaynak dalındaki sürüm **1.15.9.70003** (27 Ekim 2026). Bu bir ilk alpha paketidir; oyun içinde henüz test edilmemiştir.

## Kurulum

1. ZIP içindeki `GearTags` klasörünü `World of Warcraft\_classic_era_\Interface\AddOns\` içine çıkar.
2. Son konum `...\AddOns\GearTags\GearTags.toc` olmalı. Arada ikinci bir `GearTags` klasörü olmamalı.
3. Karakter ekranındaki AddOns listesinden **GearTags**'i etkinleştir. Oyundayken dosyaları değiştirdiysen `/reload` kullan; yeni kurulum listede görünmüyorsa oyunu yeniden başlat.
4. `/gt` yazarak veya minimap üzerindeki çanta simgesine basarak aç.

Oyun istemci sürümünü görmek için:

```text
/run print(GetBuildInfo())
```

Bu paket 60 seviye sunucularının **Classic Era istemcisi** için hazırlanmıştır. Retail, ilerleme Classic, Anniversary TBC ve Forever sürümleri için hazırlanmış değildir. Era ile istemci paylaşan diğer oyun modlarının ayrı içerik davranışları da test edilmemiştir.

## İlk kullanım

Bir eşyanın üzerine **Alt + Sağ Tık** yap. Birden fazla etiket seçebilir, satış kilidini açabilir ve not yazabilirsin. Etiket/kilit değişiklikleri hemen addon verisine işlenir; not için **Notu kaydet** düğmesini kullan.

Hazır etiketler:

| Etiket | Kullanım |
| --- | --- |
| PvE | Dungeon / raid ve diğer PvE ekipmanların |
| PvP | PvP ekipmanların |
| Essential Gear | Önemli, alternatif veya saklamak istediğin ekipmanlar |
| Gathering | Toplama meslekleriyle ilgili eşyalar |
| Crafting | Üretim malzemeleri, tarifler ve ilgili eşyalar |
| Consumables | Potion, yemek ve diğer tüketilebilir eşyalar |

**Custom** bir üst gruptur. **+ Yeni etiket** ile `Fire Resist`, `Healing Set` gibi kendi etiketlerini oluştur. Başlangıçta hiçbir eşyaya otomatik etiket veya kilit atanmaz.

**All** bütün çantayı, **Untagged** henüz etiketlenmemiş eşyaları, **Locked** ise satış kilidi verdiğin eşyaları gösterir. Bir eşyanın birden fazla etiketi olabilir. Filtre seçmek etiket atamaz.

- **Vurgula:** Slotların sırası korunur. Eşleşen eşyaların dış çerçevesi seçili etiketin renginde belirir; diğerleri soluklaşır.
- **Yalnızca göster:** GearTags penceresinde yalnızca eşleşen eşyalar listelenir. Gerçek çanta yuvaları veya eşyalar taşınmaz.
- **Arama:** Eşya adı, eşya ID'si, etiket adı veya kişisel not içinde arar. Seçili filtre ile birlikte çalışır.
- **Ayarlar:** Etiket rengini, eşleşmeyen eşyaların parlaklığını ve normal çanta katmanını ayarlar. Özel etiketleri yeniden adlandırıp silebilirsin.

Itemin kalite çerçevesi ile etiketin dış vurgu çerçevesi ayrıdır. Sol alt köşedeki renk işaretleri ilk iki etiketi gösterir; daha fazlası GearTags penceresinde `+N` olarak belirtilir. Bütün etiketler tooltip içinde görünür.

## Eşyalar nasıl takip ediliyor?

**Ekipmanlar fiziksel eşya kimliğiyle (GUID) takip edilir.** Aynı itemden iki tane olduğunda bunları ayrı etiketleyebilirsin. Çantada yerini değiştirmen veya enchant değiştirmen etiketi değiştirmez. Kimliği henüz yüklenmemiş ekipmanda düzenleme ve addon üzerinden satıcı işlemleri bekletilir.

**Diğer eşyalar item ID'siyle takip edilir.** Bir malzemeyi veya tüketilebilir eşyayı etiketlediğinde/kilitlediğinde, o karakterdeki aynı eşyanın bütün kopya ve yığınlarına uygulanır. Böylece yığın bölme veya birleştirme etiketini kaybettirmez. Eşya düzenleyicisinde ve tooltip içinde bu kapsam yazılıdır.

Etiket tanımları hesap içinde ortaktır; eşyalara atanan etiketler, kilitler, notlar ve görünüm ayarları karaktere özeldir. Özel etiketi silmek o etiketi bütün karakterlerden kaldırır; hiçbir eşyayı veya bağımsız satış kilidini silmez.

Eşyaları çantadan çıkarmak kayıtlarını silmez. Böylece önceden etiketlediğin bir ekipmanı giyip çıkardığında veya bankaya koyup geri aldığında etiketi korunur. Bu sürüm bankanın içeriğini ayrı bir envanter görünümünde listelemez.

Veriler WoW'un `GearTagsDB` SavedVariables kaydıyla tutulur. Normal çıkış ve `/reload` sırasında oyun bunları diske yazar. Addon veri dosyası `WTF\Account\...\SavedVariables\GearTags.lua` altında bulunur.

## Satış kilidinin kapsamı

Satıcı açıkken kilitli eşyaya GearTags penceresinden tıklamak/sürüklemek bir **Kilidi kaldır / Vazgeç** penceresi açar. **Kilidi kaldırmak hiçbir satış çağrısı yapmaz.** Satmak istersen eşyaya yeniden sağ tıklarsın.

**Normal çantalarda da işaretle** ayarı açıkken Blizzard'ın standart çanta düğmelerine de etiketler, vurgular ve satıcıdayken kilitli eşyalar için yerel bir tıklama katmanı eklenir. Normal çantalar her zaman vurgulama biçimini kullanır; `Yalnızca göster` yalnızca GearTags penceresini düzenler.

Bu, yüzde yüz satış/yok etme engeli değildir. Başka addonların doğrudan API üzerinden yaptığı toplu satışlar, başka çanta addonlarının kendi düğmeleri, makrolar ve önceden imlece alınan bir eşyayı doğrudan satıcıya bırakma bu kontrolü aşabilir. Silme, posta, trade ve auction işlemleri için koruma uygulanmaz. Oyun API'leri global olarak değiştirilmez.

Satıcıdayken kilitli eşyayı imlece alma da ek kontrol gerektirir. GearTags penceresi, satıcı açıkken imleç zaten doluysa işlemi bekletir. Savaşta GearTags penceresindeki eşya işlemleri kapalıdır; standart çanta tıklama katmanı da devreden çıkar. Native katman kapatılırsa normal çantalardaki kilit kontrolü de kapanır; GearTags penceresindeki kontrol devam eder.

## İlk oyun içi deneme

İlk denemeyi önemsiz bir eşya ile yap:

1. `/gt` ile aç; bir eşyaya Alt + Sağ Tık yapıp `PvE` ve `Essential Gear` ata.
2. `PvE` filtresinde Vurgula ve Yalnızca göster seçeneklerini dene.
3. Eşyayı başka çanta yuvasına taşı; etiketlerinin aynı kaldığını kontrol et.
4. Bir not yaz, Notu kaydet'e bas; tooltip içinde göründüğünü kontrol et.
5. Satış kilidini aç. Satıcıda sağ tıklayınca uyarının geldiğini, Vazgeç'in kilidi koruduğunu kontrol et.
6. Kilidi kaldır'a bas. Eşyanın satılmadığını ve ayrıca sağ tıklamak gerektiğini doğrula.
7. `/reload` sonrası etiket, not ve kilit durumunun korunduğunu kontrol et.
8. Blizzard çantalarında aynı kontrolleri dene. Kullandığın başka çanta veya otomatik satış addonuyla birlikte davranışı ayrıca kontrol et.

## Komutlar ve sorun giderme

| Komut | İşlev |
| --- | --- |
| `/gt` veya `/geartags` | Pencereyi aç / kapat |
| `/gt options` | Ayarları aç / kapat |
| `/gt minimap` | Minimap simgesini göster / gizle |
| `/gt resetpos` | Pencereyi ekranın ortasına getir |
| `/gt debug` | Addon/istemci sürümünü ve temel durumu sohbet alanına yaz |
| `/gt help` | Kısayol bilgileri |

Pencere üstünden sürüklenebilir. İlk açılışta ekran boyuna göre ölçeklenir. `Çantayla birlikte aç` ayarı varsayılan olarak açıktır; normal çantaları elle kapattığında otomatik açılan GearTags penceresi de kapanır. `/gt` ile elle açtığın pencereyi normal çantayı kapatmak kapatmaz.

Lua hatalarını görünür yapmak için `/console scriptErrors 1` ve ardından `/reload` kullan. Hata bildirirken hata metnini, hangi işlemi yaptığını, `/gt debug` çıktısını ve kullandığın diğer çanta/satış addonlarını paylaş.

## Doğrulama durumu

- Lua 5.1 sözdizimi denetimi geçti.
- **50 otomatik test** geçti: veri kalıcılığı, aynı itemin ayrı fiziksel kopyaları, malzeme yığınları, çoklu etiketler, filtre/arama, özel etiketler, kilit, taşınan/stale itemler, bankada yeniden kullanılan Blizzard çanta frame'leri, tooltip, ayarlar ve açılış akışı.
- Testlerde WoW UI/API sınırı taklit edildi. Bu sonuçlar gerçek istemcide çizim, secure execution/taint, savaş davranışı ve üçüncü taraf addon uyumluluğunun doğrulandığı anlamına gelmez.
- Gerçek oyun içi kurulum/deneme bu paketin ardından yapılmalıdır. Görsel konseptteki yapıyı oyun içi standart dokularla uygular; konsept görselinin piksel piksel kopyası değildir.

Geliştirme ve test ayrıntıları: `DEVELOPMENT.md`.

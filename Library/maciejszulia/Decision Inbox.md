---
name: Library/maciejszulia/Decision Inbox
tags: meta/library
---
A reply button for a decision inbox page. A question block calls `${type(odp) == "function" and odp("Z-2026.08.30-01") or ""}` next to its "własnymi słowami" item; the button asks for the answer, writes it into the block's `> ` line and ticks that item. Page format and limits: [README](https://github.com/maciejszulia/silverbullet/blob/main/Library/maciejszulia/README.md).

```space-lua
-- Wstawia odpowiedź ownera do bloku pytania o danym ID i odhacza „własnymi słowami”.
-- Zwraca nowy tekst strony albo nil, gdy nie ma dokładnie jednego bloku z polem.
function odpWstaw(tekstStrony, id, odpowiedz)
  local linie = {}
  for linia in string.gmatch(tekstStrony .. "\n", "([^\n]*)\n") do
    linie[#linie + 1] = linia
  end

  local function idNaglowka(linia)
    local znalezione = string.match(linia, "^### ([^ ]+)")
    if not znalezione then return nil end
    znalezione = string.gsub(znalezione, "^~~", "")
    znalezione = string.gsub(znalezione, "~~$", "")
    return znalezione
  end

  -- Edycja jest bezpieczna tylko wtedy, gdy ID wskazuje dokładnie jeden blok.
  local liczbaBlokow = 0
  for _, linia in ipairs(linie) do
    if idNaglowka(linia) == id then
      liczbaBlokow = liczbaBlokow + 1
    end
  end
  if liczbaBlokow ~= 1 then
    return nil
  end

  local poczatek = nil
  local koniec = #linie
  for i, linia in ipairs(linie) do
    if poczatek and string.find(linia, "^#+ ") then
      koniec = i - 1
      break
    end
    if idNaglowka(linia) == id then
      poczatek = i
    end
  end
  if not poczatek then
    return nil
  end

  local checkbox = nil
  local pole = nil
  for i = poczatek + 1, koniec do
    local linia = linie[i]
    if string.find(linia, "^%* %[[ xX]%] własnymi słowami") then
      if checkbox then return nil end
      checkbox = i
    elseif string.sub(linia, 1, 2) == "> " then
      if pole then return nil end
      pole = i
    end
  end
  if not checkbox or not pole then
    return nil
  end

  linie[checkbox] = string.gsub(linie[checkbox], "^%* %[ %]", "* [x]", 1)
  linie[pole] = "> " .. odpowiedz
  return table.concat(linie, "\n")
end

-- Przycisk przy pozycji „własnymi słowami”: ${type(odp) == "function" and odp("Z-2026.08.30-01") or ""}
function odp(id)
  return widget.new {
    html = "<button class='odp-btn'>Odpowiedz</button>",
    cssClasses = { "odp" },
    display = "inline",
    events = {
      click = function()
        local odpowiedz = editor.prompt("Odpowiedź na " .. id .. ":")
        if not odpowiedz or odpowiedz == "" then
          return
        end
        local nowy = odpWstaw(editor.getText(), id, odpowiedz)
        if not nowy then
          editor.flashNotification("Nie mogę bezpiecznie wskazać jednego pola odpowiedzi dla " .. id ..
            " — wpisz ręcznie pod listą.", "error")
          return
        end
        editor.setText(nowy)
        editor.save()
        editor.flashNotification("Zapisano odpowiedź na " .. id)
      end
    }
  }
end
```

## Samosprawdzenie

Komenda **Owner: sprawdź skrypt odpowiedzi** przepuszcza sztuczną stronę przez `odpWstaw`: sprawdza, czy podmiana trafia we właściwy blok (także przy polskich znakach), czy odhacza „własnymi słowami” oraz czy nieznane, podobne lub zduplikowane ID niczego nie rusza. Jeśli świeci na czerwono, przycisk też nie zadziała.

```space-lua
command.define {
  name = "Owner: sprawdź skrypt odpowiedzi",
  run = function()
    local probka = table.concat({
      "## Czeka na Ciebie",
      "",
      "### Z-TEST-01 · Pytanie z ogonkami: zażółć gęślą jaźń? #mid",
      "",
      "* [ ] `tak` — cokolwiek",
      "* [ ] odłóż na później",
      "* [ ] własnymi słowami:",
      "",
      "> _(tu wpisz odpowiedź)_",
      "",
      "---",
      "",
      "### Z-TEST-02 · Drugie pytanie",
      "",
      "* [ ] własnymi słowami:",
      "",
      "> _(tu wpisz odpowiedź)_",
      "",
      "## Odpowiedziane",
    }, "\n")

    local podobneId = table.concat({
      "## Czeka na Ciebie",
      "### Z-TEST-010 · To nie jest Z-TEST-01",
      "* [ ] własnymi słowami:",
      "> _(tu wpisz odpowiedź)_",
      "## Odpowiedziane",
    }, "\n")

    local zduplikowaneId = table.concat({
      "## Czeka na Ciebie",
      "### Z-DUP · Pierwszy blok",
      "* [ ] własnymi słowami:",
      "> _(tu wpisz odpowiedź)_",
      "### Z-DUP · Drugi blok",
      "* [ ] własnymi słowami:",
      "> _(tu wpisz odpowiedź)_",
      "## Odpowiedziane",
    }, "\n")

    local wynik = odpWstaw(probka, "Z-TEST-02", "ćwierć łódź")

    local ok = wynik
      and string.find(wynik, "> ćwierć łódź", 1, true) ~= nil
      -- pierwszy blok nietknięty: jego pole i checkboxy zostają puste
      and select(2, string.gsub(wynik, "_%(tu wpisz odpowiedź%)_", "")) == 1
      and select(2, string.gsub(wynik, "%* %[x%] własnymi słowami", "")) == 1
      -- nieznane ani tylko podobne ID nie może niczego zmienić
      and odpWstaw(probka, "Z-TEST-99", "x") == nil
      and odpWstaw(podobneId, "Z-TEST-01", "x") == nil
      and odpWstaw(zduplikowaneId, "Z-DUP", "x") == nil

    if ok then
      editor.flashNotification("Skrypt odpowiedzi: OK")
    else
      editor.flashNotification("Skrypt odpowiedzi: BŁĄD — przycisk nie zadziała", "error")
    end
  end
}
```

## Styles

```space-style
.sb-hashtag[data-tag-name="mid"],
.sb-hashtag[data-tag-name="high"],
.sb-hashtag[data-tag-name="critical"] {
  border-radius: 4px;
  padding: 0 6px;
  font-weight: 600;
  text-decoration: none;
}

.sb-hashtag[data-tag-name="mid"] { background: #f2c200; }
.sb-hashtag[data-tag-name="high"] { background: #cc2f26; }
.sb-hashtag[data-tag-name="critical"] { background: #7a1fa2; }

/* MID: ciemny tekst na żółtym. Kontrast > 7:1 w obu motywach. */
.sb-hashtag[data-tag-name="mid"],
.sb-hashtag[data-tag-name="mid"] * { color: #1a1a1a !important; }

/* HIGH / CRITICALHIGH: biały tekst na czerwonym / fioletowym. */
.sb-hashtag[data-tag-name="high"],
.sb-hashtag[data-tag-name="high"] *,
.sb-hashtag[data-tag-name="critical"],
.sb-hashtag[data-tag-name="critical"] * { color: #ffffff !important; }
```

```space-style
.odp button, button.odp-btn {
  font: inherit;
  font-size: 0.85em;
  padding: 1px 10px;
  margin-left: 6px;
  border: 1px solid #b08e00;
  border-radius: 4px;
  background: #f2c200;
  color: #1a1a1a;
  cursor: pointer;
}

.odp button:hover, button.odp-btn:hover { background: #ffd426; }

.odp button:focus-visible,
button.odp-btn:focus-visible {
  outline: 3px solid #1a1a1a;
  outline-offset: 2px;
}
```

```space-style
.sb-h3.sb-named-anchor-mark,
.sb-h3.sb-named-anchor {
  display: none;
}
```

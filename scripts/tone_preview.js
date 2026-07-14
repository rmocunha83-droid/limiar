#!/usr/bin/env node

const fs = require("node:fs/promises");
const path = require("node:path");
const passages = require("../Limiar/Resources/passages.json");
const {
  azureSpeechTone,
  callAzureSpeech,
  canonicalPassageNarrationText
} = require("../api/_limiar-ai");

const REQUIRED_ENV = ["AZURE_SPEECH_KEY", "AZURE_SPEECH_REGION"];
const OUTPUT_DIRECTORY = path.resolve(__dirname, "../preview/tone");
const PREVIEW_PASSAGE_IDS = [
  "matthew-11-protestant", // curto e com faixa: valida "versículos 28 a 30"
  "psalm-23",              // médio, referência sem versículo
  "corinthians2-4-16-protestant" // longo
];

function requireConfiguration() {
  const missing = REQUIRED_ENV.filter((name) => !String(process.env[name] || "").trim());
  if (missing.length) {
    throw new Error(`Prévia de tom exige as variáveis: ${missing.join(", ")}`);
  }
}

function selectedPassages() {
  return PREVIEW_PASSAGE_IDS.map((id) => {
    const passage = passages.find((candidate) => candidate.id === id);
    if (!passage) throw new Error(`Trecho de prévia não encontrado: ${id}`);
    return passage;
  });
}

async function main() {
  requireConfiguration();
  await fs.mkdir(OUTPUT_DIRECTORY, { recursive: true });

  const tones = [
    {
      name: "current",
      config: azureSpeechTone({
        rate: "-8%",
        pitch: null,
        breakMs: 0,
        proclaimReference: false,
        referenceSpeechVersion: "legacy"
      })
    },
    { name: "serene", config: azureSpeechTone() }
  ];

  const generated = [];
  for (const passage of selectedPassages()) {
    const input = canonicalPassageNarrationText(passage.reference, passage.text);
    for (const tone of tones) {
      const filename = `${tone.name}-${passage.id}.mp3`;
      const pathname = path.join(OUTPUT_DIRECTORY, filename);
      const audio = await callAzureSpeech({
        input,
        tone: tone.config,
        debugContext: { endpoint: "tone_preview", passageID: passage.id, tone: tone.name }
      });
      await fs.writeFile(pathname, audio);
      generated.push(pathname);
      console.log(`${tone.name}: ${passage.reference} -> ${pathname}`);
    }
  }

  console.log(`\nPrévia concluída: ${generated.length} arquivos locais em ${OUTPUT_DIRECTORY}`);
  console.log("Ouça e aprove o tom sereno antes de qualquer deploy ou prewarm.");
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}

module.exports = {
  OUTPUT_DIRECTORY,
  PREVIEW_PASSAGE_IDS,
  requireConfiguration,
  selectedPassages
};

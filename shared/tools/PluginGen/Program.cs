// Generates the ESP for an MTF plugin connector, matching MTF's own plugin ESPs
// (vendor/magic-tattoos-framework/spriggit/MTF_Plugin_BFNG):
// one Start Game Enabled quest carrying the plugin script, and a PluginKickAlias
// forced to the player carrying MTF_PluginAliasKick.
//
// Usage: PluginGen --out <path/To/MTF_Plugin_X.esp> --script <MTF_Plugin_X> --name <quest name>
//                  [--author <text>] [--description <text>]
using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Plugins.Binary.Parameters;
using Mutagen.Bethesda.Plugins.Records;
using Mutagen.Bethesda.Skyrim;

var options = ParseArgs(args);
string Required(string key) =>
    options.TryGetValue(key, out var value) && value.Length > 0
        ? value
        : throw new ArgumentException($"Missing --{key}. Usage: PluginGen --out <esp> --script <name> --name <quest name> [--author <text>] [--description <text>]");

var outputPath = Path.GetFullPath(Required("out"));
var scriptName = Required("script");
var questName = Required("name");
options.TryGetValue("author", out var author);
options.TryGetValue("description", out var description);

var modKey = ModKey.FromFileName(Path.GetFileName(outputPath));
var mod = new SkyrimMod(modKey, SkyrimRelease.SkyrimSE);
var playerRef = new FormKey(ModKey.FromFileName("Skyrim.esm"), 0x14);

var quest = new Quest(new FormKey(modKey, 0x800), SkyrimRelease.SkyrimSE)
{
    EditorID = scriptName,
    Name = questName,
    Flags = Quest.Flag.StartGameEnabled,
    NextAliasID = 1,
};
quest.Aliases.Add(new QuestAlias
{
    ID = 0,
    Name = "PluginKickAlias",
    ForcedReference = new FormLinkNullable<IPlacedGetter>(playerRef),
});

var questAdapter = new QuestAdapter
{
    Version = 5,
    ObjectFormat = 2,
};
questAdapter.Scripts.Add(new ScriptEntry
{
    Name = scriptName,
    Flags = ScriptEntry.Flag.Local,
});
var kickAlias = new QuestFragmentAlias
{
    Property = new ScriptObjectProperty
    {
        Name = "",
        Object = new FormLink<ISkyrimMajorRecordGetter>(quest.FormKey),
        Alias = 0,
    },
};
kickAlias.Scripts.Add(new ScriptEntry
{
    Name = "MTF_PluginAliasKick",
    Flags = ScriptEntry.Flag.Local,
});
questAdapter.Aliases.Add(kickAlias);
quest.VirtualMachineAdapter = questAdapter;
mod.Quests.Add(quest);

mod.ModHeader.Author = string.IsNullOrEmpty(author) ? null : author;
mod.ModHeader.Description = string.IsNullOrEmpty(description) ? null : description;
mod.ModHeader.MasterReferences.Clear();
foreach (var master in new[] { "Skyrim.esm", "MagicTattoosFramework.esp" })
{
    mod.ModHeader.MasterReferences.Add(new MasterReference
    {
        Master = ModKey.FromFileName(master),
    });
}
// Light plugin: ESL flag on the esp. Not an .esl, because this file masters an esp.
mod.IsSmallMaster = true;

var outputDir = Path.GetDirectoryName(outputPath)!;
Directory.CreateDirectory(outputDir);
mod.WriteToBinary(outputPath, new BinaryWriteParameters
{
    MastersListContent = MastersListContentOption.NoCheck,
});
Console.WriteLine($"Wrote {outputPath}");

// Start-game-enabled quests in a non-master plugin start from this file, including on an existing save.
// Seq entries are file-relative FormIDs: the top byte is the plugin's own index, which is its master count.
var seqDir = Path.Combine(outputDir, "Seq");
Directory.CreateDirectory(seqDir);
var seqPath = Path.Combine(seqDir, Path.GetFileNameWithoutExtension(outputPath) + ".seq");
var seqFormId = ((uint)mod.ModHeader.MasterReferences.Count << 24) | quest.FormKey.ID;
using (var seq = File.Create(seqPath))
using (var writer = new BinaryWriter(seq))
{
    writer.Write(seqFormId);
}
Console.WriteLine($"Wrote {seqPath} ({seqFormId:X8})");

using var check = SkyrimMod.CreateFromBinaryOverlay(outputPath, SkyrimRelease.SkyrimSE);
var savedQuest = check.Quests.Single();
var savedAdapter = savedQuest.VirtualMachineAdapter!;
Console.WriteLine($"Light {check.IsSmallMaster}, masters: " + string.Join(", ", check.ModHeader.MasterReferences.Select(m => m.Master.ToString())));
Console.WriteLine($"Quest {savedQuest.FormKey.ID:X6} {savedQuest.EditorID} flags {savedQuest.Flags} scripts [{string.Join(", ", savedAdapter.Scripts.Select(s => s.Name))}]");
foreach (var alias in savedQuest.Aliases)
    Console.WriteLine($"  Alias {alias.ID} {alias.Name} forced {alias.ForcedReference.FormKeyNullable}");
foreach (var alias in ((IQuestAdapterGetter)savedAdapter).Aliases)
    Console.WriteLine($"  Alias scripts [{string.Join(", ", alias.Scripts.Select(s => s.Name))}]");

static Dictionary<string, string> ParseArgs(string[] args)
{
    var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    for (var i = 0; i < args.Length; i++)
    {
        if (!args[i].StartsWith("--"))
            throw new ArgumentException($"Unexpected argument '{args[i]}'.");
        if (i + 1 >= args.Length)
            throw new ArgumentException($"{args[i]} needs a value.");
        result[args[i][2..]] = args[++i];
    }
    return result;
}

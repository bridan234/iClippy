import { useState, useEffect, useRef } from "react";
import { Clipboard } from "lucide-react";
import { ClipboardItem, ClipboardEntry } from "./components/ClipboardItem";
import { SearchBar } from "./components/SearchBar";
import { Button } from "./components/ui/button";
import { toast } from "sonner@2.0.3";

// Mock clipboard data
const mockClipboardData: ClipboardEntry[] = [
  {
    id: "1",
    content: "import { useState } from 'react';",
    type: "code",
    timestamp: new Date(Date.now() - 1000 * 60 * 5), // 5 minutes ago
  },
  {
    id: "2",
    content: "https://www.figma.com/design/example-file",
    type: "text",
    timestamp: new Date(Date.now() - 1000 * 60 * 30), // 30 minutes ago
  },
  {
    id: "3",
    content: "Meeting notes:\n- Discussed Q4 roadmap\n- Product launch scheduled for December\n- Need to finalize marketing materials",
    type: "text",
    timestamp: new Date(Date.now() - 1000 * 60 * 60 * 2), // 2 hours ago
  },
  {
    id: "4",
    content: "const handleSubmit = async (data) => {\n  await submitForm(data);\n};",
    type: "code",
    timestamp: new Date(Date.now() - 1000 * 60 * 60 * 5), // 5 hours ago
  },
  {
    id: "5",
    content: "Design system colors: #3B82F6, #8B5CF6, #EC4899",
    type: "text",
    timestamp: new Date(Date.now() - 1000 * 60 * 60 * 24), // 1 day ago
  },
  {
    id: "6",
    content: "screenshot-2024-dashboard.png",
    type: "image",
    timestamp: new Date(Date.now() - 1000 * 60 * 60 * 24 * 2), // 2 days ago
  },
];

export default function App() {
  const [clipboardHistory, setClipboardHistory] = useState<ClipboardEntry[]>(mockClipboardData);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedIndex, setSelectedIndex] = useState(0);
  const itemRefs = useRef<(HTMLDivElement | null)[]>([]);

  const filteredHistory = clipboardHistory.filter((entry) =>
    entry.content.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Reset selected index when search changes
  useEffect(() => {
    setSelectedIndex(0);
  }, [searchQuery]);

  // Keyboard navigation
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (filteredHistory.length === 0) return;

      switch (e.key) {
        case "ArrowDown":
          e.preventDefault();
          setSelectedIndex((prev) => 
            prev < filteredHistory.length - 1 ? prev + 1 : prev
          );
          break;
        case "ArrowUp":
          e.preventDefault();
          setSelectedIndex((prev) => (prev > 0 ? prev - 1 : prev));
          break;
        case "Enter":
          e.preventDefault();
          if (filteredHistory[selectedIndex]) {
            handleCopy(filteredHistory[selectedIndex].id);
          }
          break;
        case "Backspace":
        case "Delete":
          if (e.target instanceof HTMLInputElement) return; // Don't delete when typing
          e.preventDefault();
          if (filteredHistory[selectedIndex]) {
            handleDelete(filteredHistory[selectedIndex].id);
          }
          break;
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [filteredHistory, selectedIndex]);

  // Scroll selected item into view
  useEffect(() => {
    if (itemRefs.current[selectedIndex]) {
      itemRefs.current[selectedIndex]?.scrollIntoView({
        behavior: "smooth",
        block: "nearest",
      });
    }
  }, [selectedIndex]);

  const handleCopy = (id: string) => {
    const entry = clipboardHistory.find((e) => e.id === id);
    if (entry) {
      navigator.clipboard.writeText(entry.content);
      toast.success("Copied! Ready to paste (⌘V)");
    }
  };

  const handleDelete = (id: string) => {
    setClipboardHistory((prev) => prev.filter((e) => e.id !== id));
    toast.success("Item deleted");
    // Adjust selected index if needed
    if (selectedIndex >= filteredHistory.length - 1) {
      setSelectedIndex(Math.max(0, filteredHistory.length - 2));
    }
  };

  const handleClearAll = () => {
    setClipboardHistory([]);
    toast.success("Clipboard history cleared");
  };

  return (
    <div className="w-[480px] bg-white/95 backdrop-blur-xl rounded-xl shadow-2xl border border-gray-200/50 overflow-hidden">
      <div className="flex flex-col max-h-[600px]">
        {/* Search */}
        <div className="p-3 border-b border-gray-200/50">
          <SearchBar value={searchQuery} onChange={setSearchQuery} />
        </div>

        {/* Clipboard History */}
        <div className="overflow-y-auto max-h-[480px]">
          {filteredHistory.length > 0 ? (
            <div className="py-1">
              {filteredHistory.map((entry, index) => (
                <div
                  key={entry.id}
                  ref={(el) => (itemRefs.current[index] = el)}
                  onClick={() => handleCopy(entry.id)}
                  className="cursor-pointer"
                >
                  <ClipboardItem
                    entry={entry}
                    onCopy={handleCopy}
                    onDelete={handleDelete}
                    isSelected={index === selectedIndex}
                  />
                </div>
              ))}
            </div>
          ) : (
            <div className="py-12 text-center">
              <Clipboard className="h-8 w-8 text-gray-300 mx-auto mb-2" />
              <p className="text-gray-500 text-sm">
                {searchQuery ? "No matching items" : "No clipboard history"}
              </p>
            </div>
          )}
        </div>

        {/* Footer */}
        {clipboardHistory.length > 0 && (
          <div className="px-3 py-2 border-t border-gray-200/50 bg-gray-50/50 flex items-center justify-between">
            <p className="text-xs text-gray-500">
              ↑↓ Navigate • ⏎ Copy • ⌫ Delete
            </p>
            <Button
              variant="ghost"
              onClick={handleClearAll}
              className="h-6 px-2 text-xs text-gray-500 hover:text-gray-900"
            >
              Clear
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}
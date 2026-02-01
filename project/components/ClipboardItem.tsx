import { Copy, Trash2 } from "lucide-react";
import { Button } from "./ui/button";

export interface ClipboardEntry {
  id: string;
  content: string;
  type: "text" | "image" | "code";
  timestamp: Date;
}

interface ClipboardItemProps {
  entry: ClipboardEntry;
  onCopy: (id: string) => void;
  onDelete: (id: string) => void;
  isSelected?: boolean;
}

export function ClipboardItem({ entry, onCopy, onDelete, isSelected = false }: ClipboardItemProps) {
  const formatTime = (date: Date) => {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 1) return "Just now";
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    return `${days}d ago`;
  };

  const getTypeColor = () => {
    switch (entry.type) {
      case "code":
        return "bg-blue-500/10 text-blue-600";
      case "image":
        return "bg-purple-500/10 text-purple-600";
      default:
        return "bg-gray-500/10 text-gray-600";
    }
  };

  return (
    <div className={`group relative rounded-md px-3 py-2.5 transition-all duration-150 ${
      isSelected 
        ? 'bg-blue-500 text-white' 
        : 'hover:bg-gray-100/80'
    }`}>
      <div className="flex items-start gap-3">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <span className={`text-xs px-1.5 py-0.5 rounded ${
              isSelected 
                ? 'bg-white/20 text-white' 
                : getTypeColor()
            }`}>
              {entry.type}
            </span>
            <span className={`text-xs ${
              isSelected ? 'text-white/70' : 'text-gray-400'
            }`}>
              {formatTime(entry.timestamp)}
            </span>
          </div>
          <p className={`line-clamp-2 whitespace-pre-wrap break-words text-sm ${
            isSelected ? 'text-white' : 'text-gray-700'
          }`}>
            {entry.content}
          </p>
        </div>
        <div className={`flex gap-1 transition-opacity ${
          isSelected ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'
        }`}>
          <Button
            variant="ghost"
            size="sm"
            onClick={(e) => {
              e.stopPropagation();
              onCopy(entry.id);
            }}
            className={`h-7 w-7 p-0 ${
              isSelected ? 'hover:bg-white/20' : ''
            }`}
          >
            <Copy className={`h-3.5 w-3.5 ${
              isSelected ? 'text-white' : 'text-gray-500'
            }`} />
            <span className="sr-only">Copy</span>
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={(e) => {
              e.stopPropagation();
              onDelete(entry.id);
            }}
            className={`h-7 w-7 p-0 ${
              isSelected ? 'hover:bg-white/20' : ''
            }`}
          >
            <Trash2 className={`h-3.5 w-3.5 ${
              isSelected ? 'text-white' : 'text-gray-500'
            }`} />
            <span className="sr-only">Delete</span>
          </Button>
        </div>
      </div>
    </div>
  );
}
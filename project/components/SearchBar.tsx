import { Search } from "lucide-react";
import { Input } from "./ui/input";

interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
}

export function SearchBar({ value, onChange }: SearchBarProps) {
  return (
    <div className="relative">
      <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-gray-400" />
      <Input
        type="text"
        placeholder="Search clipboard history..."
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="pl-9 h-8 text-sm bg-white/50 border-gray-200 focus:border-gray-300 focus:ring-0 focus:bg-white"
      />
    </div>
  );
}
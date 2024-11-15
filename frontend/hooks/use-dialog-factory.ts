import { useState, ReactNode } from "react";

export type DialogView = {
  title: string;
  content: (props: { setView: (viewKey: DialogViewKey) => void }) => ReactNode;
};

export type DialogViewKey = string;

export function useDialogFactory(
  initialViews: Record<DialogViewKey, DialogView>
) {
  const [views, setViews] = useState(initialViews);
  const [currentViewKey, setCurrentViewKey] = useState<DialogViewKey>(
    Object.keys(initialViews)[0]
  );

  const setView = (viewKey: DialogViewKey) => {
    if (views[viewKey]) {
      setCurrentViewKey(viewKey);
    } else {
      console.error(`View "${viewKey}" not found`);
    }
  };

  const addView = (viewKey: DialogViewKey, view: DialogView) => {
    setViews((prevViews) => ({ ...prevViews, [viewKey]: view }));
  };

  const currentView = {
    ...views[currentViewKey],
    content: views[currentViewKey].content({ setView }),
  };

  return {
    currentView,
    setView,
    addView,
  };
}

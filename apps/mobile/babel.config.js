module.exports = function(api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      // Removed deprecated react-native-reanimated/plugin
      // Use react-native-worklets/plugin if worklets are needed
    ],
  };
};